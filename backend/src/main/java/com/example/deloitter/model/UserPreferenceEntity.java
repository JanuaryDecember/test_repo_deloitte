package com.example.deloitter.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "user_preferences")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPreferenceEntity {

    @Id
    private UUID id;

    private String businessPreference;

    private String skillset;

    private String characterTrait;

    private String careerInterest;

    private String workingStyle;

    private String learningGoal;

    @OneToOne
    @JoinColumn(name = "user_id")
    private UserEntity user;
}
