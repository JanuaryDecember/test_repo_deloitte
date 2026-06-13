package com.example.deloitter.config;

import com.example.deloitter.model.UserEntity;
import com.example.deloitter.model.UserPreferenceEntity;
import com.example.deloitter.service.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.UUID;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    private final UserRepository repository;

    @Bean
    CommandLineRunner initData() {

        return args -> {

            UserEntity john = UserEntity.builder()
                    .id(UUID.randomUUID())
                    .firstName("John")
                    .lastName("Smith")
                    .email("john@company.com")
                    .build();

            UserPreferenceEntity johnPrefs =
                    UserPreferenceEntity.builder()
                            .id(UUID.randomUUID())
                            .businessPreference("FinTech")
                            .skillset("Java")
                            .characterTrait("Analytical")
                            .careerInterest("Architecture")
                            .workingStyle("Hybrid")
                            .learningGoal("AI")
                            .user(john)
                            .build();

            john.setPreferences(johnPrefs);

            UserEntity anna = UserEntity.builder()
                    .id(UUID.randomUUID())
                    .firstName("Anna")
                    .lastName("Brown")
                    .email("anna@company.com")
                    .build();

            UserPreferenceEntity annaPrefs =
                    UserPreferenceEntity.builder()
                            .id(UUID.randomUUID())
                            .businessPreference("Healthcare")
                            .skillset("Python")
                            .characterTrait("Empathetic")
                            .careerInterest("Leadership")
                            .workingStyle("Remote")
                            .learningGoal("Cloud")
                            .user(anna)
                            .build();

            anna.setPreferences(annaPrefs);

            repository.save(john);
            repository.save(anna);
        };
    }
}
