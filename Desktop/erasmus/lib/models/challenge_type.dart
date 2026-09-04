/// Challenge test type enum
enum ChallengeType {
  englishSkills,
  projectFit,
}

extension ChallengeTypeExt on ChallengeType {
  String get displayName {
    switch (this) {
      case ChallengeType.englishSkills:
        return 'English Skills Test';
      case ChallengeType.projectFit:
        return 'Project Fit Test';
    }
  }

  String get screenTitle {
    switch (this) {
      case ChallengeType.englishSkills:
        return 'English Skills Test';
      case ChallengeType.projectFit:
        return 'Project Fit Test';
    }
  }

  String get screenDescription {
    switch (this) {
      case ChallengeType.englishSkills:
        return 'Answer the questions to evaluate your English communication skills.';
      case ChallengeType.projectFit:
        return 'Answer project-specific scenarios to evaluate your fit for the selected opportunity.';
    }
  }
}
