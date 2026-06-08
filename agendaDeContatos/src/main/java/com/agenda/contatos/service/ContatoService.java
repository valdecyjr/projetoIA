package com.agenda.contatos.service;

import com.agenda.contatos.dto.ContatoRequestDTO;
import com.agenda.contatos.dto.ContatoResponseDTO;
import com.agenda.contatos.exception.ResourceNotFoundException;
import com.agenda.contatos.model.Contato;
import com.agenda.contatos.repository.ContatoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContatoService {

    private final ContatoRepository contatoRepository;

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    public ContatoResponseDTO addContato(ContatoRequestDTO request) {
        Contato contato = convertToEntity(request);
        Contato savedContato = contatoRepository.save(contato);
        return convertToResponseDTO(savedContato);
    }

    public void removeContato(UUID id) {
        Contato contato = contatoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contato não encontrado com o ID: " + id));
        
        // Optionally delete the photo if it exists
        if (contato.getFotoUrl() != null) {
            deletePhotoFile(contato.getFotoUrl());
        }
        
        contatoRepository.delete(contato);
    }

    public List<ContatoResponseDTO> listContatos() {
        return contatoRepository.findAll().stream()
                .map(this::convertToResponseDTO)
                .collect(Collectors.toList());
    }

    public ContatoResponseDTO getContatoById(UUID id) {
        Contato contato = contatoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contato não encontrado com o ID: " + id));
        return convertToResponseDTO(contato);
    }

    public List<ContatoResponseDTO> getContatosByNome(String nome) {
        return contatoRepository.findByNomeContainingIgnoreCase(nome).stream()
                .map(this::convertToResponseDTO)
                .collect(Collectors.toList());
    }

    public ContatoResponseDTO uploadFoto(UUID id, MultipartFile file) {
        Contato contato = contatoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contato não encontrado com o ID: " + id));

        if (file.isEmpty()) {
            throw new IllegalArgumentException("O arquivo de foto enviado está vazio.");
        }

        try {
            // Create upload folder if it doesn't exist
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // Get original file extension
            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }

            // Generate unique file name
            String fileName = id.toString() + "_" + System.currentTimeMillis() + extension;
            Path filePath = uploadPath.resolve(fileName);

            // Copy file to local directory
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // If there was an old photo, delete it
            if (contato.getFotoUrl() != null) {
                deletePhotoFile(contato.getFotoUrl());
            }

            // Update photo URL (relative to local server)
            String fotoUrl = "/uploads/" + fileName;
            contato.setFotoUrl(fotoUrl);

            Contato updatedContato = contatoRepository.save(contato);
            return convertToResponseDTO(updatedContato);

        } catch (IOException e) {
            throw new RuntimeException("Falha ao salvar o arquivo de foto no servidor.", e);
        }
    }

    private void deletePhotoFile(String fotoUrl) {
        try {
            String fileName = fotoUrl.substring(fotoUrl.lastIndexOf("/") + 1);
            Path filePath = Paths.get(uploadDir).resolve(fileName);
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            // Log warning or ignore deletion failure
            System.err.println("Erro ao deletar o arquivo da foto antiga: " + e.getMessage());
        }
    }

    private ContatoResponseDTO convertToResponseDTO(Contato contato) {
        return ContatoResponseDTO.builder()
                .id(contato.getId())
                .nome(contato.getNome())
                .telefone(contato.getTelefone())
                .email(contato.getEmail())
                .fotoUrl(contato.getFotoUrl())
                .build();
    }

    private Contato convertToEntity(ContatoRequestDTO requestDTO) {
        return Contato.builder()
                .nome(requestDTO.getNome())
                .telefone(requestDTO.getTelefone())
                .email(requestDTO.getEmail())
                .build();
    }
}
