package com.example.deloitter.model;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

@Data
@Builder
public class MatchResponseDto {

    private UUID userId;

    private String firstName;

    private String lastName;

    private Integer matchScore;
}
