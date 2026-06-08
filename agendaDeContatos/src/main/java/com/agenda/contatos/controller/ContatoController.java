package com.agenda.contatos.controller;

import com.agenda.contatos.dto.ContatoRequestDTO;
import com.agenda.contatos.dto.ContatoResponseDTO;
import com.agenda.contatos.service.ContatoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/contatos")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // Habilitar CORS para facilitar integração com front-ends
public class ContatoController {

    private final ContatoService contatoService;

    @PostMapping
    public ResponseEntity<ContatoResponseDTO> addContato(@Valid @RequestBody ContatoRequestDTO request) {
        ContatoResponseDTO response = contatoService.addContato(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> removeContato(@PathVariable UUID id) {
        contatoService.removeContato(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<List<ContatoResponseDTO>> listContatos() {
        List<ContatoResponseDTO> response = contatoService.listContatos();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ContatoResponseDTO> getContatoById(@PathVariable UUID id) {
        ContatoResponseDTO response = contatoService.getContatoById(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/buscar")
    public ResponseEntity<List<ContatoResponseDTO>> getContatosByNome(@RequestParam("nome") String nome) {
        List<ContatoResponseDTO> response = contatoService.getContatosByNome(nome);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/foto")
    public ResponseEntity<ContatoResponseDTO> uploadFoto(@PathVariable UUID id, @RequestParam("foto") MultipartFile foto) {
        ContatoResponseDTO response = contatoService.uploadFoto(id, foto);
        return ResponseEntity.ok(response);
    }
}
