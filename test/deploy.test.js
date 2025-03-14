const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("ImageSignatureStorage Deployment", function () {
  it("Should deploy the ImageSignatureStorage contract", async function () {
    // コントラクトのファクトリを作成
    const ImageSignatureStorage = await ethers.getContractFactory("ImageSignatureStorage");
    
    // コントラクトをデプロイ
    const storage = await ImageSignatureStorage.deploy();
    
    // デプロイ完了を待機
    await storage.deploymentTransaction();
    
    // コントラクトのアドレスが存在することを確認
    const contractAddress = await storage.getAddress();
    expect(contractAddress).to.be.a('string');
    expect(contractAddress).to.not.equal('');
    
    console.log("ImageSignatureStorage deployed to:", contractAddress);
  });
});