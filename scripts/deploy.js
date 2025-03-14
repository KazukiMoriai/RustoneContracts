const { ethers } = require("hardhat");

async function main() {
  // コントラクトをデプロイするアカウントを取得
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  
  // デプロイ前の残高をチェック
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  // コントラクトのファクトリを作成
  const ImageSignatureStorage = await ethers.getContractFactory("ImageSignatureStorage");
  
  // コントラクトをデプロイ
  const storage = await ImageSignatureStorage.deploy();
  
  // デプロイ完了を待機
  await storage.deploymentTransaction();
  
  console.log("ImageSignatureStorage deployed to:", await storage.getAddress());
}

// エラーハンドリングを含むメイン関数の実行
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });