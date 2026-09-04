// Data-driven scenarios for Mini Erasmus Challenge
// Each scenario contains: title, question, options (text + contributions)

final List<Map<String, dynamic>> gameScenarios = [
  {
    'title': 'Team Conflict',
    'question': 'Two team members constantly clash over task distribution, meetings are unproductive. An activity day is coming and everyone is stressed. What do you do?',
    'options': [
      {
        'text': 'Listen to both sides separately, find common ground, and reorganize tasks with mini-mediation.',
        'contrib': {
          'teamwork': 3,
          'communication': 3,
          'responsibility': 1,
          'interculturalAwareness': 1,
          'problemSolving': 2,
          'motivation': 1,
          'adaptability': 1,
          'leadership': 2,
        }
      },
      {
        'text': 'Report the situation to the coordinator and wait for them to resolve it.',
        'contrib': {
          'teamwork': 1,
          'communication': 1,
          'responsibility': 2,
          'interculturalAwareness': 0,
          'problemSolving': 1,
          'motivation': 0,
          'adaptability': 0,
          'leadership': 0,
        }
      },
      {
        'text': 'Focus on my own work; the conflicts are not my concern.',
        'contrib': {
          'teamwork': 0,
          'communication': 0,
          'responsibility': 0,
          'interculturalAwareness': 0,
          'problemSolving': 0,
          'motivation': 0,
          'adaptability': 0,
          'leadership': 0,
        }
      }
    ]
  },
  {
    'title': 'Cultural Misunderstanding',
    'question': 'At a local event, you accidentally made an inappropriate joke and some participants are offended. What do you do?',
    'options': [
      {
        'text': 'Apologize immediately, explain your intention, and invite the same person to an event to learn about their culture.',
        'contrib': {'teamwork':1,'communication':3,'responsibility':2,'interculturalAwareness':3,'problemSolving':1,'motivation':1,'adaptability':1,'leadership':0}
      },
      {
        'text': 'Offer a brief apology but try not to make a big deal out of it.',
        'contrib': {'teamwork':0,'communication':1,'responsibility':1,'interculturalAwareness':1,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      },
      {
        'text': 'This is our culture; those who don\'t understand have a problem.',
        'contrib': {'teamwork':0,'communication':0,'responsibility':0,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      }
    ]
  },
  {
    'title': 'Budget Cuts',
    'question': 'The event budget is cut in half, but we still want to run the event. What do you suggest?',
    'options': [
      {
        'text': 'Research alternative sponsors, venues, or volunteer resources. Scale the event but keep the core objectives intact.',
        'contrib': {'teamwork':2,'communication':1,'responsibility':2,'interculturalAwareness':0,'problemSolving':3,'motivation':1,'adaptability':1,'leadership':2}
      },
      {
        'text': 'Simplify the event and cancel some activities.',
        'contrib': {'teamwork':1,'communication':0,'responsibility':1,'interculturalAwareness':0,'problemSolving':1,'motivation':0,'adaptability':0,'leadership':0}
      },
      {
        'text': 'Cancel the event; I don\'t want to take the risk.',
        'contrib': {'teamwork':0,'communication':0,'responsibility':0,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      }
    ]
  },
  {
    'title': 'Health & Morale',
    'question': 'Accommodation is poor in the first week and a few people are slightly unwell; morale is low. What do you do?',
    'options': [
      {
        'text': 'Organize a small morale-boosting activity, coordinate needs, and share tasks to relax the team.',
        'contrib': {'teamwork':2,'communication':2,'responsibility':1,'interculturalAwareness':1,'problemSolving':1,'motivation':3,'adaptability':1,'leadership':2}
      },
      {
        'text': 'Focus on my own tasks; I can\'t deal with morale issues.',
        'contrib': {'teamwork':0,'communication':0,'responsibility':1,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      },
      {
        'text': 'Consider leaving the project.',
        'contrib': {'teamwork':0,'communication':0,'responsibility':0,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      }
    ]
  },
  {
    'title': 'Language & Communication',
    'question': 'At the event, several participants have limited English. How do you include them in group work?',
    'options': [
      {
        'text': 'Use simple language, incorporate visuals and translation tools, and assign small tasks to everyone.',
        'contrib': {'teamwork':2,'communication':3,'responsibility':1,'interculturalAwareness':2,'problemSolving':1,'motivation':1,'adaptability':1,'leadership':0}
      },
      {
        'text': 'Work only with English speakers; non-speakers fend for themselves.',
        'contrib': {'teamwork':0,'communication':1,'responsibility':0,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      },
      {
        'text': 'Language barriers don\'t concern me; I\'ll do the work anyway.',
        'contrib': {'teamwork':0,'communication':0,'responsibility':0,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      }
    ]
  },
  {
    'title': 'Task Prioritization',
    'question': 'Report submission, volunteering duties, and event responsibilities all fall in the same week. Your plan?',
    'options': [
      {
        'text': 'Prioritize tasks, delegate within the team, use time blocking, and share urgency transparently.',
        'contrib': {'teamwork':2,'communication':1,'responsibility':3,'interculturalAwareness':0,'problemSolving':2,'motivation':1,'adaptability':1,'leadership':1}
      },
      {
        'text': 'Complete the report first, then handle the others later.',
        'contrib': {'teamwork':0,'communication':0,'responsibility':2,'interculturalAwareness':0,'problemSolving':1,'motivation':0,'adaptability':0,'leadership':0}
      },
      {
        'text': 'Try to do everything at once; I might fail.',
        'contrib': {'teamwork':0,'communication':0,'responsibility':0,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      }
    ]
  },
  {
    'title': 'Sustainable Engagement',
    'question': 'You want to start a sustainable activity during the project; resources are limited but the idea is strong. What do you do?',
    'options': [
      {
        'text': 'Start a small pilot, measure results, and collaborate with local stakeholders.',
        'contrib': {'teamwork':2,'communication':2,'responsibility':2,'interculturalAwareness':1,'problemSolving':2,'motivation':2,'adaptability':1,'leadership':3}
      },
      {
        'text': 'Note the idea but wait for implementation until resources are available.',
        'contrib': {'teamwork':0,'communication':1,'responsibility':1,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      },
      {
        'text': 'Don\'t push the idea; without resources, I won\'t implement it.',
        'contrib': {'teamwork':0,'communication':0,'responsibility':0,'interculturalAwareness':0,'problemSolving':0,'motivation':0,'adaptability':0,'leadership':0}
      }
    ]
  }
];
