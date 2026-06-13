package com.example.deloitter.model;

import lombok.Data;

@Data
public class MatchRequestDto {

    private String businessPreference;

    private String skillset;

    private String characterTrait;

    private String careerInterest;

    private String workingStyle;

    private String learningGoal;
}
