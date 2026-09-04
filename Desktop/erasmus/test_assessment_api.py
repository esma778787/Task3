import json
import os
import unittest
import uuid

from app import app


def _normalize_email(email: str) -> str:
    return email.strip().lower()


class AssessmentApiTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        app.config["TESTING"] = True
        cls.client = app.test_client()
        cls.email = _normalize_email(f"testuser+{uuid.uuid4().hex[:8]}@example.com")
        cls.name = "Test User"
        cls.gender = "Kız"
        cls.challenge_type = "english_placement"

    def test_01_create_session(self):
        payload = {
            "user": {
                "email": self.email,
                "name": self.name,
                "gender": self.gender,
            },
            "challengeType": self.challenge_type,
            "project": {
                "projectId": "50361",
                "title": "Example ESC Project",
                "sourceName": "European Youth Portal",
                "sourceUrl": "https://youth.europa.eu/solidarity/opportunity/50361_en",
            },
        }

        response = self.client.post("/api/assessment-sessions", json=payload)
        self.assertEqual(response.status_code, 201)
        data = response.get_json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], "started")
        self.__class__.session_id = data["sessionId"]

    def test_02_create_second_session_same_email(self):
        payload = {
            "user": {
                "email": self.email,
                "name": "Test User Updated",
                "gender": self.gender,
            },
            "challengeType": self.challenge_type,
            "project": {
                "projectId": "50362",
                "title": "Example ESC Project 2",
                "sourceName": "European Youth Portal",
                "sourceUrl": "https://youth.europa.eu/solidarity/opportunity/50362_en",
            },
        }

        response = self.client.post("/api/assessment-sessions", json=payload)
        self.assertEqual(response.status_code, 201)
        data = response.get_json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], "started")
        self.__class__.second_session_id = data["sessionId"]

    def test_03_save_english_result(self):
        payload = {
            "result": {
                "estimatedLevel": "B1",
                "percentage": 68.5,
                "correctAnswers": 21,
                "incorrectAnswers": 9,
                "earnedWeightedScore": 61,
                "maximumWeightedScore": 89,
                "skillScores": {
                    "grammar": 70,
                    "vocabulary": 75,
                    "reading": 55,
                    "communication": 80,
                    "useOfEnglish": 62,
                },
                "strengths": ["Vocabulary", "Communication"],
                "weaknesses": ["Reading"],
                "aiFeedback": "Generated feedback",
                "feedbackSource": "openrouter",
                "aiModel": None,
            },
            "answers": [
                {
                    "questionId": "eng_b1_001",
                    "displayOrder": 1,
                    "questionType": "multiple_choice_cloze",
                    "skill": "grammar",
                    "cefrLevel": "B1",
                    "questionText": "Question text",
                    "passageText": None,
                    "options": ["A", "B", "C", "D"],
                    "selectedOptionIndex": 1,
                    "textAnswer": None,
                    "isCorrect": True,
                    "earnedScore": 2,
                    "maximumScore": 2,
                }
            ],
        }

        response = self.client.post(
            f"/api/assessment-sessions/{self.session_id}/english-result",
            json=payload,
        )
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], "completed")

    def test_04_idempotent_english_result(self):
        payload = {
            "result": {
                "estimatedLevel": "B1",
                "percentage": 68.5,
                "correctAnswers": 21,
                "incorrectAnswers": 9,
                "earnedWeightedScore": 61,
                "maximumWeightedScore": 89,
                "skillScores": {
                    "grammar": 70,
                    "vocabulary": 75,
                    "reading": 55,
                    "communication": 80,
                    "useOfEnglish": 62,
                },
                "strengths": ["Vocabulary", "Communication"],
                "weaknesses": ["Reading"],
                "aiFeedback": "Generated feedback",
                "feedbackSource": "openrouter",
                "aiModel": None,
            },
            "answers": [
                {
                    "questionId": "eng_b1_001",
                    "displayOrder": 1,
                    "questionType": "multiple_choice_cloze",
                    "skill": "grammar",
                    "cefrLevel": "B1",
                    "questionText": "Question text",
                    "passageText": None,
                    "options": ["A", "B", "C", "D"],
                    "selectedOptionIndex": 1,
                    "textAnswer": None,
                    "isCorrect": True,
                    "earnedScore": 2,
                    "maximumScore": 2,
                }
            ],
        }

        response = self.client.post(
            f"/api/assessment-sessions/{self.session_id}/english-result",
            json=payload,
        )
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data["success"])

    def test_05_get_session_result(self):
        response = self.client.get(f"/api/assessment-sessions/{self.session_id}")
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["session"]["sessionId"], self.session_id)
        self.assertEqual(data["session"]["status"], "completed")
        self.assertIsNotNone(data["englishResult"])
        self.assertEqual(len(data["answers"]), 1)

    def test_06_get_user_history(self):
        response = self.client.get(f"/api/users/{self.email}/assessment-history?page=1&pageSize=20")
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["page"], 1)
        self.assertEqual(data["pageSize"], 20)
        self.assertGreaterEqual(data["total"], 2)
        self.assertTrue(any(item["sessionId"] == self.session_id for item in data["items"]))

    def test_07_invalid_payload(self):
        response = self.client.post("/api/assessment-sessions", json={})
        self.assertEqual(response.status_code, 400)

    def test_08_invalid_challenge_type(self):
        payload = {
            "user": {
                "email": self.email,
                "name": self.name,
                "gender": self.gender,
            },
            "challengeType": "unsupported_type",
            "project": {},
        }
        response = self.client.post("/api/assessment-sessions", json=payload)
        self.assertEqual(response.status_code, 400)


if __name__ == "__main__":
    unittest.main()
