package com.agenda.contatos.repository;

import com.agenda.contatos.model.Contato;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ContatoRepository extends JpaRepository<Contato, UUID> {
    
    List<Contato> findByNomeContainingIgnoreCase(String nome);
}
