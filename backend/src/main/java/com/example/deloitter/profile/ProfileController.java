package com.example.deloitter.profile;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping
    public ResponseEntity<ProfileResponse> getProfile() {
        return ResponseEntity.ok(profileService.getProfile());
    }

    @GetMapping("/selections")
    public ResponseEntity<SelectionsResponse> getSelections() {
        return ResponseEntity.ok(profileService.getSelections());
    }

    @PutMapping("/selections")
    public ResponseEntity<SelectionsResponse> updateSelections(@RequestBody SelectionsRequest request) {
        return ResponseEntity.ok(profileService.updateSelections(request));
    }
}
