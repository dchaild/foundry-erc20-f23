-include .env

.PHONY: all test deploy

build :; forge build
test :; forge test --fork-url $(RPC_URL) --ffi
deploy :; forge script script/DeployRaffle.s.sol:DeployRaffle --fork-url $(RPC_URL) --broadcast -vvvv
all : build test deploy
install :; forge install cyfrin/foundry-devops@0.2.2 forge install cyfrin/smartcontractkit/chainlink-brownie-contracts@1.1.1 && forge install foundry-rs/forge-std@1.8.2 && forge install transmissions11/solmate@v6
deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --fork-url $(SEPOLIA_RPC_URL) --account disney --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
deploy-mumbai:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --fork-url $(MUMBAI_RPC_URL) --account disney --broadcast --verify --polygonscan-api-key $(POLYGONSCAN_API_KEY) -vvvv
deploy-anvil:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --fork-url $(ANVIL_RPC_URL) --account disney --broadcast -vvvv