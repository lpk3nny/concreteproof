// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract BeerConsumer is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    string public lastBeerName; // Сюда сохраним результат
    bytes32 public lastRequestId;

    // Адрес роутера зависит от сети (напр. Sepolia: 0xb83E47C2... )
    constructor(address router) FunctionsClient(router) {}

    function requestBeerData(
        string calldata source, // Тот самый JS код выше
        uint64 subscriptionId, // Твой ID подписки в Chainlink
        uint32 gasLimit,
        bytes32 donID
    ) external returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);

        lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        return lastRequestId;
    }

    // Callback, который вызовет Chainlink, когда получит данные из API
    function fulfillRequest(
        bytes32 /* requestId */, // Имя удалено или закомментировано
        bytes memory response,
        bytes memory err
    ) internal override {
        if (err.length > 0) {
            // Логика обработки ошибки (по желанию)
            return;
        }
        lastBeerName = string(response);
    }
}
