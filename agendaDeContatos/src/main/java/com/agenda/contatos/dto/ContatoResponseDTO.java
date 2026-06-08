package com.agenda.contatos.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ContatoResponseDTO {

    private UUID id;
    private String nome;
    private String telefone;
    private String email;
    private String fotoUrl;
}
