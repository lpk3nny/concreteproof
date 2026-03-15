// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ConreteProof is FunctionsClient, Ownable {
    using FunctionsRequest for FunctionsRequest.Request;

    // Структура для хранения деталей запроса
    struct RequestDetail {
        string url;
        bytes32 resultHash;
        bool fulfilled;
    }

    // Храним детали по ID запроса (как в базе данных по Primary Key)
    mapping(bytes32 => RequestDetail) public requests;
    
    // Список всех ID для итерации на фронтенде
    bytes32[] public requestIds;

    string public source;
    address public router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 public donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    event RequestSent(bytes32 indexed requestId, string url);
    event ResponseReceived(bytes32 indexed requestId, bytes32 hash);

    constructor(string memory initialSource) 
        FunctionsClient(router) 
        Ownable(msg.sender) 
    {
        source = initialSource;
    }

    function setSource(string calldata newSource) external onlyOwner {
        source = newSource;
    }

    function hashHTTPResponse(uint64 subscriptionId, string calldata apiUrl) external returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); 
        
        string[] memory args = new string[](1);
        args[0] = apiUrl;
        req.setArgs(args);
        
        bytes32 requestId = _sendRequest(req.encodeCBOR(), subscriptionId, 300000, donID);
        
        // Сохраняем метаданные запроса
        requests[requestId] = RequestDetail({
            url: apiUrl,
            resultHash: bytes32(0),
            fulfilled: false
        });
        requestIds.push(requestId);

        emit RequestSent(requestId, apiUrl);
        return requestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory /* err */
    ) internal override {
        if (response.length == 32) {
            bytes32 hashResult = abi.decode(response, (bytes32));
            
            // Обновляем данные в маппинге по ключу requestId
            requests[requestId].resultHash = hashResult;
            requests[requestId].fulfilled = true;

            emit ResponseReceived(requestId, hashResult);
        }
    }

    // Хелпер для фронтенда: получить все ID запросов
    function getRequestHistory() external view returns (bytes32[] memory) {
        return requestIds;
    }
}
