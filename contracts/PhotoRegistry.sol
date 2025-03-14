// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ImageSignatureStorage
 * @dev カメラで撮影した画像のメタデータと署名を保存するためのスマートコントラクト
 */
contract ImageSignatureStorage {
    // イメージデータの構造体
    struct ImageData {
        string imageUrl;      // 画像のURL
        string imageHash;     // 画像のハッシュ値
        uint256 timestamp;    // タイムスタンプ
        bytes signature;      // 署名データ
        address owner;        // 所有者（撮影者）のアドレス
    }

    // イメージIDからイメージデータへのマッピング
    mapping(uint256 => ImageData) public images;
    
    // アドレスからそのアドレスが所有する画像IDの配列へのマッピング
    mapping(address => uint256[]) public userImages;
    
    // ハッシュから画像IDへのマッピング（重複チェック用）
    mapping(string => bool) public hashExists;

    // 保存されたイメージの総数
    uint256 public imageCount;

    // イベント定義
    event ImageStored(uint256 indexed imageId, address indexed owner, string imageHash, uint256 timestamp);
    event ImageDeleted(uint256 indexed imageId, address indexed owner);

    /**
     * @dev 画像メタデータと署名を保存
     * @param _imageUrl 画像のURL
     * @param _imageHash 画像のハッシュ値
     * @param _timestamp タイムスタンプ
     * @param _signature 署名データ
     */
    function storeImage(
        string memory _imageUrl,
        string memory _imageHash,
        uint256 _timestamp,
        bytes memory _signature
    ) external {
        // 重複チェック
        require(!hashExists[_imageHash], "Image with this hash already exists");
        
        // 基本的な入力検証
        require(bytes(_imageUrl).length > 0, "Image URL cannot be empty");
        require(bytes(_imageHash).length > 0, "Image hash cannot be empty");
        require(_timestamp > 0, "Timestamp cannot be zero");
        require(_signature.length > 0, "Signature cannot be empty");

        // 新しいイメージIDを生成
        uint256 imageId = imageCount + 1;
        
        // イメージデータを保存
        images[imageId] = ImageData({
            imageUrl: _imageUrl,
            imageHash: _imageHash,
            timestamp: _timestamp,
            signature: _signature,
            owner: msg.sender
        });
        
        // ユーザーの画像リストに追加
        userImages[msg.sender].push(imageId);
        
        // ハッシュの存在を記録
        hashExists[_imageHash] = true;
        
        // イメージカウントを増加
        imageCount++;
        
        // イベント発行
        emit ImageStored(imageId, msg.sender, _imageHash, _timestamp);
    }

/**
 * @dev イメージデータを取得
 * @param _imageId 取得するイメージのID
 * @return imageUrl 画像のURL
 * @return imageHash 画像のハッシュ値
 * @return timestamp タイムスタンプ
 * @return signature 署名データ
 * @return owner 所有者アドレス
 */
    function getImage(uint256 _imageId) external view returns (
        string memory imageUrl,
        string memory imageHash,
        uint256 timestamp,
        bytes memory signature,
        address owner
    ) {
        require(_imageId > 0 && _imageId <= imageCount, "Image does not exist");
        
        ImageData storage image = images[_imageId];
        return (
            image.imageUrl,
            image.imageHash,
            image.timestamp,
            image.signature,
            image.owner
        );
    }

    /**
     * @dev 所有者がイメージを削除
     * @param _imageId 削除するイメージのID
     */
    function deleteImage(uint256 _imageId) external {
        require(_imageId > 0 && _imageId <= imageCount, "Image does not exist");
        require(images[_imageId].owner == msg.sender, "Only owner can delete the image");
        
        // ハッシュの存在フラグを削除
        hashExists[images[_imageId].imageHash] = false;
        
        // イメージデータを削除
        delete images[_imageId];
        
        // ユーザーの画像リストから削除（効率のため、厳密な削除ではなく無効化）
        // 完全な削除が必要な場合は、配列のフィルタリングが必要
        
        // イベント発行
        emit ImageDeleted(_imageId, msg.sender);
    }

    /**
     * @dev ユーザーの全画像IDを取得
     * @param _owner 画像の所有者アドレス
     * @return ユーザーが所有する画像IDの配列
     */
    function getUserImages(address _owner) external view returns (uint256[] memory) {
        return userImages[_owner];
    }

    /**
     * @dev 署名を検証する関数
     * @param _imageHash 画像のハッシュ値
     * @param _timestamp タイムスタンプ
     * @param _signature 署名データ
     * @param _signer 署名者のアドレス
     * @return 署名が有効かどうか
     */
    function verifySignature(
        string memory _imageHash,
        uint256 _timestamp,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        // 署名対象のメッセージハッシュを生成
        bytes32 messageHash = keccak256(abi.encodePacked(_imageHash, _timestamp));
        
        // Ethereumの署名形式にするためのプレフィックスを追加
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        
        // 署名を検証
        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    /**
     * @dev 署名から署名者のアドレスを回復する関数
     * @param _ethSignedMessageHash 署名されたメッセージハッシュ
     * @param _signature 署名データ
     * @return 署名者のアドレス
     */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover関数で使用するために署名を分解
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // v値を27か28に調整
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature recovery value");

        // 署名者のアドレスを回復
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
} 