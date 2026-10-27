// leitura e escrita de json com um unico mapper, imutavel e thread-safe depois do build
package br.com.horselife.microchip.utilitarios;

import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.MapperFeature;
import tools.jackson.databind.cfg.CoercionAction;
import tools.jackson.databind.cfg.CoercionInputShape;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.type.LogicalType;

public final class UtilitarioJson {

    private static final JsonMapper MAPPER = JsonMapper.builder()
            .disable(MapperFeature.SORT_PROPERTIES_ALPHABETICALLY)
            .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .enable(DeserializationFeature.FAIL_ON_TRAILING_TOKENS)
            .withCoercionConfig(LogicalType.Textual, config -> config
                    .setCoercion(CoercionInputShape.Integer, CoercionAction.Fail)
                    .setCoercion(CoercionInputShape.Float, CoercionAction.Fail)
                    .setCoercion(CoercionInputShape.Boolean, CoercionAction.Fail))
            .build();

    private UtilitarioJson() {
    }

    public static <T> T ler(String json, Class<T> tipo) {
        return MAPPER.readValue(json, tipo);
    }

    public static String escrever(Object valor) {
        return MAPPER.writeValueAsString(valor);
    }
}
