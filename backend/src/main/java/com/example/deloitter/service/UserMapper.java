package com.example.deloitter.service;

import com.example.deloitter.model.UserDto;
import com.example.deloitter.model.UserEntity;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface UserMapper {

    UserDto toDto(UserEntity entity);

    UserEntity toEntity(UserDto dto);
}
