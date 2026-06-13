package com.example.deloitter.catalog;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/catalog")
public class CatalogController {

    private final InterestRepository interestRepository;
    private final CompetencyRepository competencyRepository;

    public CatalogController(InterestRepository interestRepository, CompetencyRepository competencyRepository) {
        this.interestRepository = interestRepository;
        this.competencyRepository = competencyRepository;
    }

    @GetMapping
    public CatalogResponse getCatalog() {
        List<CatalogItem> interests = interestRepository.findAll().stream()
                .map(i -> new CatalogItem(i.getId(), i.getName()))
                .toList();
        List<CatalogItem> competencies = competencyRepository.findAll().stream()
                .map(c -> new CatalogItem(c.getId(), c.getName()))
                .toList();
        return new CatalogResponse(interests, competencies);
    }
}
