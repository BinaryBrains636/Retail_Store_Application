package com.retail.users.service;

import com.retail.users.dto.UserDTO;
import com.retail.users.model.User;
import com.retail.users.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    public List<UserDTO> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public Optional<UserDTO> getUserById(Long id) {
        return userRepository.findById(id)
                .map(this::convertToDTO);
    }

    public Optional<UserDTO> getUserByUsername(String username) {
        return userRepository.findByUsername(username)
                .map(this::convertToDTO);
    }

    public UserDTO createUser(UserDTO userDTO) {
        if (userRepository.existsByUsername(userDTO.getUsername())) {
            throw new RuntimeException("Username already exists");
        }
        if (userRepository.existsByEmail(userDTO.getEmail())) {
            throw new RuntimeException("Email already exists");
        }

        User user = convertToEntity(userDTO);
        User savedUser = userRepository.save(user);
        return convertToDTO(savedUser);
    }

    public Optional<UserDTO> updateUser(Long id, UserDTO userDTO) {
        return userRepository.findById(id)
                .map(user -> {
                    user.setUsername(userDTO.getUsername());
                    user.setEmail(userDTO.getEmail());
                    user.setFirstName(userDTO.getFirstName());
                    user.setLastName(userDTO.getLastName());
                    user.setActive(userDTO.getActive());
                    User updatedUser = userRepository.save(user);
                    return convertToDTO(updatedUser);
                });
    }

    public boolean deleteUser(Long id) {
        if (userRepository.existsById(id)) {
            userRepository.deleteById(id);
            return true;
        }
        return false;
    }

    private UserDTO convertToDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setFirstName(user.getFirstName());
        dto.setLastName(user.getLastName());
        dto.setActive(user.getActive());
        return dto;
    }

    private User convertToEntity(UserDTO dto) {
        User user = new User();
        user.setUsername(dto.getUsername());
        user.setEmail(dto.getEmail());
        user.setFirstName(dto.getFirstName());
        user.setLastName(dto.getLastName());
        user.setActive(dto.getActive() != null ? dto.getActive() : true);
        return user;
    }
}
