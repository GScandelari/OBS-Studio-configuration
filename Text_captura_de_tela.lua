obs           	= obslua
nome_fonte 		= ""
segundos_totais = 0
segundos_atuais = 0
ultimo_texto	= ""
texto_final 	= ""
ativado			= false
hotkey_id     	= obs.OBS_INVALID_HOTKEY_ID

-- Função para definir o texto da hora
function definir_texto_hora()
	local texto_vazio = ""

	if segundos_atuais > 0 then
		texto_vazio = texto_final
	end

	if texto_vazio ~= ultimo_texto then
		
		local fonte = obs.obs_get_source_by_name(nome_fonte)
		if fonte ~= nil then
			local configuracao = obs.obs_data_create()
			obs.obs_data_set_string(configuracao, "text", texto_vazio)
			obs.obs_source_update(fonte, configuracao)
			obs.obs_data_release(configuracao)
			obs.obs_source_release(fonte)
		end
	end
	ultimo_texto = texto_vazio
end

function cronometro()
	segundos_atuais = segundos_atuais - 1
	if segundos_atuais < 0 then
		obs.remove_current_callback()
		segundos_atuais = 0
	end
	definir_texto_hora()
end

function ativar(ativando)
	if ativado == ativando then
		return
	end
	ativado = ativando
	if ativando then
		segundos_atuais = segundos_totais
		definir_texto_hora()
		obs.timer_add(cronometro, 1000)
	else
		obs.timer_remove(cronometro)
	end
end

-- Chamado quando uma fonte está ativado/desativado
function ativar_sinal(cd, ativando)
	local fonte = obs.calldata_source(cd, "fonte")
	if fonte ~= nil then
		local nome = obs.obs_source_get_name(fonte)
		if (nome == nome_fonte) then
			ativar(ativando)
		end
	end
end

function fonte_ativada(cd)
	ativar_sinal(cd, true)
end

function fonte_desativada(cd)
	ativar_sinal(cd, false)
end

function reiniciar(pressed)
	if not pressed then
		return
	end
	ativar(false)
	local fonte = obs.obs_get_source_by_name(nome_fonte)
	if fonte ~= nil then
		local ativo = obs.obs_source_active(fonte)
		obs.obs_source_release(fonte)
		ativar(ativo)
	end
end

function btn_Salvar_clicked(props, p)
	reiniciar(true)
	return false
end

----------------------------------------------------------

-- Função script_properties define as propriedades que o usuário pode mudar para todo o módulo de script em si
function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_int(props, "_tempo_max", "Tempo do aviso (segundos)", 1, 10, 1)

	local p = obs.obs_properties_add_list(props, "fonte", "Fonte de Texto", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local fontes = obs.obs_enum_sources()
	if fontes ~= nil then
		for _, fonte in ipairs(fontes) do
			fonte_id = obs.obs_source_get_unversioned_id(fonte)
			if fonte_id == "text_gdiplus" or fonte_id == "text_ft2_source" then
				local nome = obs.obs_source_get_name(fonte)
				obs.obs_property_list_add_string(p, nome, nome)
			end
		end
	end
	obs.source_list_release(fontes)

	obs.obs_properties_add_text(props, "_msg_aviso", "Mensagem de aviso", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_button(props, "_btn_Salvar", "Salver e reiniciar", btn_Salvar_clicked)

	return props
end

-- Função chamada script_description retorna a descrição mostrada ao usuário
function script_description()
	return "ScreenCap - versão 1.0 \n\nConfigura uma fonte de texto para receber uma mensagem específica por um determinado tempo. \n\n Desenvolvido por Guilherme S. Scandelari"
end

-- Função chamada script_update será chamada quando a configuração for alterada
function script_update(configuracao)
	ativar(false)

	segundos_totais = obs.obs_data_get_int(configuracao, "_tempo_max")
	nome_fonte = obs.obs_data_get_string(configuracao, "fonte")
	texto_final = obs.obs_data_get_string(configuracao, "_msg_aviso")

	reiniciar(true)
end

-- Função chamada script_defaults será chamada para definir a configuração padrão
function script_defaults(configuracao)
	obs.obs_data_set_default_int(configuracao, "_tempo_max", 4)
	obs.obs_data_set_default_string(configuracao, "_msg_aviso", "Tela capturada")
end

-- Função chamada script_save será chamada quando o script for salvo
--
-- NOTA: Esta função é normalmente usada para salvar dados extras (como, neste caso, salvar dados de uma tecla de atalho). 
-- As configurações definidas por meio das propriedades são salvas automaticamente.
function script_save(configuracao)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(configuracao, "reiniciar_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

-- Função chamada script_load será chamada na inicialização
function script_load(configuracao)
	-- Vincula a tecla de atalho com a chamada de sinal de ativação / desativação
	--
	-- NOTA: Esses retornos de chamada de script específicos não precisam necessariamente
	-- ser desconectado, pois os retornos de chamada se destruirão automaticamente
	-- se o script for descarregado. Portanto, não há necessidade real de manualmente
	-- desconecte retornos de chamada que devem durar até que o script seja descarregado.
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "fonte_ativada", fonte_ativada)
	obs.signal_handler_connect(sh, "fonte_desativada", fonte_desativada)

	hotkey_id = obs.obs_hotkey_register_frontend("reiniciar_cronometro", "Capturar tela - hotkey", reiniciar)
	local hotkey_save_array = obs.obs_data_get_array(configuracao, "reiniciar_hotkey")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end
