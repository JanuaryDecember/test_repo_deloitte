package com.example.deloitter.catalog;

import java.util.List;

public record CatalogResponse(List<CatalogItem> interests, List<CatalogItem> competencies) {}
