# client.py
import base64
import os
import requests

from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

SERVER = "http://localhost:8000"

# 1) Generate user RSA key pair
user_priv = rsa.generate_private_key(public_exponent=65537, key_size=4096)
user_pub = user_priv.public_key()

user_pub_pem = user_pub.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
)
user_priv_pem = user_priv.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)

user_id = "user-1234-py"  # choose stable id for tests

# 2) Upload user's public key to server
resp = requests.post(f"{SERVER}/upload-user-public-key", json={
    "user_id": user_id,
    "user_public_pem_b64": base64.b64encode(user_pub_pem).decode()
})
resp.raise_for_status()
print("Uploaded user public key:", resp.json())

# 3) Fetch server public key
resp = requests.get(f"{SERVER}/server-public-key")
resp.raise_for_status()
server_pub_pem_b64 = resp.json()["server_public_pem_b64"]
server_pub_pem = base64.b64decode(server_pub_pem_b64)

# Load server public key
from cryptography.hazmat.primitives import serialization
server_pub = serialization.load_pem_public_key(server_pub_pem)

# 4) Prepare prompt and hybrid-encrypt it
prompt = "Hello LLM from Python client. Please summarize this."
# 4a) ephemeral AES key
aes_key = AESGCM.generate_key(bit_length=256)  # bytes
aesgcm = AESGCM(aes_key)
iv = os.urandom(12)
ciphertext = aesgcm.encrypt(iv, prompt.encode("utf8"), associated_data=None)

# 4b) encrypt AES key with server RSA public key (OAEP SHA256)
enc_key = server_pub.encrypt(
    aes_key,
    padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None)
)

payload = {
    "user_id": user_id,
    "encrypted_key_b64": base64.b64encode(enc_key).decode(),
    "iv_b64": base64.b64encode(iv).decode(),
    "ciphertext_b64": base64.b64encode(ciphertext).decode()
}

# 5) Send to server
r = requests.post(f"{SERVER}/send", json=payload)
r.raise_for_status()
j = r.json()
print("Server returned:", j.keys())

# 6) Decrypt server's response
enc_resp_key = base64.b64decode(j["encrypted_key_b64"])
resp_iv = base64.b64decode(j["iv_b64"])
resp_ct = base64.b64decode(j["ciphertext_b64"])

# Decrypt AES key with user's private key
resp_aes_key = user_priv.decrypt(
    enc_resp_key,
    padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None)
)

aesgcm_resp = AESGCM(resp_aes_key)
plaintext = aesgcm_resp.decrypt(resp_iv, resp_ct, associated_data=None)
print("LLM reply:", plaintext.decode("utf8"))
