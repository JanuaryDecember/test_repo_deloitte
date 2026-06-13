package com.example.deloitter.service;

import com.example.deloitter.model.MatchRequestDto;
import com.example.deloitter.model.MatchResponseDto;
import com.example.deloitter.model.UserEntity;
import com.example.deloitter.model.UserPreferenceEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MatchingServiceImpl implements MatchingService {

    private final UserRepository userRepository;

    @Override
    public MatchResponseDto findBestMatch(MatchRequestDto request) {

        List<UserEntity> users = userRepository.findAll();

        UserEntity bestMatch = null;
        int highestScore = -1;

        for (UserEntity user : users) {

            int score = calculateScore(
                    request,
                    user.getPreferences());

            if (score > highestScore) {
                highestScore = score;
                bestMatch = user;
            }
        }

        if (bestMatch == null) {
            throw new RuntimeException("No users found");
        }

        return MatchResponseDto.builder()
                .userId(bestMatch.getId())
                .firstName(bestMatch.getFirstName())
                .lastName(bestMatch.getLastName())
                .matchScore(highestScore)
                .build();
    }

    private int calculateScore(
            MatchRequestDto request,
            UserPreferenceEntity pref) {

        int score = 0;

        if (request.getBusinessPreference()
                .equalsIgnoreCase(pref.getBusinessPreference()))
            score += 20;

        if (request.getSkillset()
                .equalsIgnoreCase(pref.getSkillset()))
            score += 25;

        if (request.getCharacterTrait()
                .equalsIgnoreCase(pref.getCharacterTrait()))
            score += 15;

        if (request.getCareerInterest()
                .equalsIgnoreCase(pref.getCareerInterest()))
            score += 15;

        if (request.getWorkingStyle()
                .equalsIgnoreCase(pref.getWorkingStyle()))
            score += 15;

        if (request.getLearningGoal()
                .equalsIgnoreCase(pref.getLearningGoal()))
            score += 10;

        return score;
    }
}
