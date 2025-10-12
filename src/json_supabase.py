import os, datetime
from supabase import create_client, Client

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
sb: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def to_date(s: str | None) -> str | None:
    if not s:
        return None
    # Accept "YYYY-MM-DD"
    return s

def upsert_member(payload: dict):
    acc = payload["accountInfo"]
    person = payload["personalInfo"]

    member_row = {
        "member_id":           acc["memberId"],
        "username":            acc.get("username"),
        "email":               acc.get("email"),
        "phone":               acc.get("phone"),
        "first_name":          person.get("firstName"),
        "last_name":           person.get("lastName"),
        "date_of_birth":       to_date(person.get("dateOfBirth")),
        "member_since":        to_date(acc.get("memberSince")),
        "elite_status":        acc.get("eliteStatus"),
        "lifetime_nights":     acc.get("lifetimeNights"),
        "current_year_nights": acc.get("currentYearNights"),
        "points_balance":      acc.get("pointsBalance"),
        "address":             person.get("address"),
        "emergency_contact":   person.get("emergencyContact"),
        "room_preferences":          payload.get("roomPreferences"),
        "dining_preferences":        payload.get("diningPreferences"),
        "service_preferences":       payload.get("servicePreferences"),
        "wellness_preferences":      payload.get("wellnessPreferences"),
        "business_preferences":      payload.get("businessPreferences"),
        "loyalty_preferences":       payload.get("loyaltyPreferences"),
        "transportation_preferences":payload.get("transportationPreferences"),
        "special_occasions":         payload.get("specialOccasions"),
        "travel_companions_meta":    payload.get("travelCompanions"),
        "cultural_preferences":      payload.get("culturalPreferences"),
        "technology_preferences":    payload.get("technologyPreferences"),
    }

    # Upsert members
    sb.table("members").upsert(member_row, on_conflict="member_id").execute()

    member_id = acc["memberId"]

    # Refresh child tables: simple approach = delete + insert (idempotent for demos)
    sb.table("travel_companions").delete().eq("member_id", member_id).execute()
    for c in payload.get("travelCompanions", {}).get("frequentCompanions", []):
        sb.table("travel_companions").insert({
            "member_id": member_id,
            "name": c.get("name"),
            "relationship": c.get("relationship"),
            "companion_member_id": c.get("memberId"),
        }).execute()

    sb.table("recent_stays").delete().eq("member_id", member_id).execute()
    for s in payload.get("recentStays", []):
        sb.table("recent_stays").insert({
            "member_id": member_id,
            "property": s.get("property"),
            "check_in": to_date(s.get("checkIn")),
            "check_out": to_date(s.get("checkOut")),
            "room_type": s.get("roomType"),
            "rating": s.get("rating"),
        }).execute()

    sb.table("upcoming_reservations").delete().eq("member_id", member_id).execute()
    for r in payload.get("upcomingReservations", []):
        sb.table("upcoming_reservations").insert({
            "member_id": member_id,
            "confirmation_number": r.get("confirmationNumber"),
            "property": r.get("property"),
            "check_in": to_date(r.get("checkIn")),
            "check_out": to_date(r.get("checkOut")),
            "room_type": r.get("roomType"),
            "special_requests": r.get("specialRequests"),
        }).execute()

def get_member(member_id: str) -> dict:
    # Join with child tables for a hydrated view
    member = sb.table("members").select("*").eq("member_id", member_id).single().execute().data
    companions = sb.table("travel_companions").select("*").eq("member_id", member_id).execute().data
    stays = sb.table("recent_stays").select("*").eq("member_id", member_id).order("check_in", desc=True).execute().data
    upcoming = sb.table("upcoming_reservations").select("*").eq("member_id", member_id).order("check_in").execute().data
    return {
        "member": member,
        "companions": companions,
        "recentStays": stays,
        "upcomingReservations": upcoming
    }
