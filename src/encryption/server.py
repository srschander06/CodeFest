# server.py
import base64
import os
from typing import Dict

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# ========== Configuration / Key management ==========
SERVER_PRIV_PATH = "server_priv.pem"
SERVER_PUB_PATH = "server_pub.pem"

def ensure_server_keys():
    if os.path.exists(SERVER_PRIV_PATH) and os.path.exists(SERVER_PUB_PATH):
        with open(SERVER_PRIV_PATH, "rb") as f:
            priv = serialization.load_pem_private_key(f.read(), password=None)
        with open(SERVER_PUB_PATH, "rb") as f:
            pub_pem = f.read()
        return priv, pub_pem
    # generate keys
    priv = rsa.generate_private_key(public_exponent=65537, key_size=4096)
    priv_pem = priv.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    pub_pem = priv.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    with open(SERVER_PRIV_PATH, "wb") as f:
        f.write(priv_pem)
    with open(SERVER_PUB_PATH, "wb") as f:
        f.write(pub_pem)
    return priv, pub_pem

SERVER_PRIVATE_KEY, SERVER_PUBLIC_PEM = ensure_server_keys()

# In-memory mapping user_id -> user_public_pem
user_public_keys: Dict[str, bytes] = {}

# ========== FastAPI setup ==========
app = FastAPI(title="E2E RSA+AES Demo (FastAPI)")

class UploadUserKey(BaseModel):
    user_id: str
    user_public_pem_b64: str  # base64 of PEM bytes

class SendPayload(BaseModel):
    user_id: str
    encrypted_key_b64: str   # AES key encrypted with server public key (base64)
    iv_b64: str
    ciphertext_b64: str      # AES-GCM ciphertext (includes tag at end)

@app.get("/server-public-key")
def get_server_public_key():
    # Return PEM as base64 so clients can easily reconstruct bytes
    return {"server_public_pem_b64": base64.b64encode(SERVER_PUBLIC_PEM).decode()}

@app.post("/upload-user-public-key")
def upload_user_public_key(payload: UploadUserKey):
    try:
        pem_bytes = base64.b64decode(payload.user_public_pem_b64)
        # Quick validation: try loading
        serialization.load_pem_public_key(pem_bytes)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid public key PEM: {e}")
    user_public_keys[payload.user_id] = pem_bytes
    return {"ok": True}

@app.post("/send")
def receive_encrypted(payload: SendPayload):
    if payload.user_id not in user_public_keys:
        raise HTTPException(status_code=400, detail="User public key not registered on server")

    try:
        # 1) decrypt AES key with server private key (RSA-OAEP SHA256)
        enc_key = base64.b64decode(payload.encrypted_key_b64)
        aes_key = SERVER_PRIVATE_KEY.decrypt(
            enc_key,
            padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None)
        )
        if len(aes_key) not in (16, 24, 32):
            # Expect AES key length (we use 32 for AES-256)
            raise ValueError("unexpected AES key length")

        # 2) decrypt ciphertext using AES-GCM
        iv = base64.b64decode(payload.iv_b64)
        ct = base64.b64decode(payload.ciphertext_b64)
        aesgcm = AESGCM(aes_key)
        # AESGCM expects tag appended to ciphertext (cryptography does this convention)
        plaintext = aesgcm.decrypt(iv, ct, associated_data=None)
        client_prompt = plaintext.decode("utf8")
        print("Received prompt (preview):", client_prompt[:200])

        # 3) (Simulate) call LLM -> produce response
        llm_response = fake_llm_response(client_prompt)

        # 4) Encrypt response to user's public key using hybrid scheme
        user_pub_pem = user_public_keys[payload.user_id]
        user_pub = serialization.load_pem_public_key(user_pub_pem)

        # 4a) ephemeral AES key + IV
        response_aes_key = AESGCM.generate_key(bit_length=256)  # 32 bytes
        response_iv = os.urandom(12)
        aesgcm_resp = AESGCM(response_aes_key)
        resp_ct = aesgcm_resp.encrypt(response_iv, llm_response.encode("utf8"), associated_data=None)
        # 4b) encrypt AES key with user's RSA public key (OAEP SHA-256)
        enc_resp_key = user_pub.encrypt(
            response_aes_key,
            padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None)
        )

        # Return base64-encoded pieces
        return {
            "encrypted_key_b64": base64.b64encode(enc_resp_key).decode(),
            "iv_b64": base64.b64encode(response_iv).decode(),
            "ciphertext_b64": base64.b64encode(resp_ct).decode()
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def fake_llm_response(prompt: str) -> str:
    # Replace this with your real LLM code (calls to OpenAI, llama, etc.)
    return f"LLM reply (simulated): echo -> {prompt}"

if __name__ == "__main__":
    import uvicorn
<<<<<<< HEAD
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
=======
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
>>>>>>> adc1b0126e9876ddeaf4e8e752515a3d07d6fb3e
