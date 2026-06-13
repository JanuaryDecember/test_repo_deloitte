# Matching API - Quick Postman Guide

## Start the Application

Run the application from IntelliJ by starting:

```text
MatchingApplication.java
```

The API will be available at:

```text
http://localhost:8080
```

---

## Test the Matching Endpoint

### Request

**Method:** `POST`

**URL:**

```text
http://localhost:8080/api/matching/best-match
```

### Headers

```text
Content-Type: application/json
```

### Body (raw JSON)

```json
{
  "businessPreference": "FinTech",
  "skillset": "Java",
  "characterTrait": "Analytical",
  "careerInterest": "Architecture",
  "workingStyle": "Hybrid",
  "learningGoal": "AI"
}
```

### Example Response

```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "firstName": "John",
  "lastName": "Smith",
  "matchScore": 100
}
```

## Notes

* Sample users are automatically loaded when the application starts.
* No database setup is required (H2 in-memory database is used).
* Restarting the application resets all data to the default sample dataset.
