package com.example.deloitter.profile;

public record ProfileResponse(
        Long id,
        String firstName,
        String lastName,
        String email,
        String serviceLine,
        String roleFamily,
        String contactInfo,
        String initials
) {}
