// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract BeerHashStore is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    // Массив для хранения всех полученных хешей
    bytes32[] public allHashes;

    // JS-код теперь использует Functions.makeHttpRequest с аргументом [0] (наш URL)
    // и хеширует весь результат через SHA256
    string public source = 
        "const url = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({ url });"
        "if (apiResponse.error) throw Error('API Error');"
        "const stringData = JSON.stringify(apiResponse.data);"
        "const hash = Crypto.createHash('sha256').update(stringData).digest('hex');"
        "return Functions.encodeBytes('0x' + hash);";

    // Константы для Sepolia
    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    constructor() FunctionsClient(router) {}

    /**
     * @param subscriptionId Твой ID подписки
     * @param apiUrl Ссылка, например "https://api.sampleapis.com/beers/ale"
     */
    function requestBeerHash(uint64 subscriptionId, string calldata apiUrl) external returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); 
        
        string[] memory args = new string[](1);
        args[0] = apiUrl; // Присваиваем первому элементу массива
        req.setArgs(args);
        
        return _sendRequest(req.encodeCBOR(), subscriptionId, 300000, donID);
    }

    function fulfillRequest(
        bytes32 /* requestId */,
        bytes memory response,
        bytes memory /* err */ // Закомментировали имя переменной
    ) internal override {
        if (response.length > 0) {
            // Мы используем abi.decode, чтобы корректно преобразовать bytes в bytes32
            bytes32 hashResult = abi.decode(response, (bytes32));
            allHashes.push(hashResult);
        }
    }

    // Хелпер для получения количества хешей (удобно для фронтенда)
    function getHashesCount() external view returns (uint256) {
        return allHashes.length;
    }
}
