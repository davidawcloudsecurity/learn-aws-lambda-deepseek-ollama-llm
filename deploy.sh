#!/bin/bash
set -e

# Configuration
STACK_NAME="ollama-deepseek-api"
KEY_PAIR_NAME=""
INSTANCE_TYPE="t3.large"
ALLOWED_CIDR="0.0.0.0/0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -k, --key-pair KEY_PAIR_NAME    EC2 Key Pair name (required)"
    echo "  -t, --instance-type TYPE        Instance type (default: t3.large)"
    echo "  -c, --cidr CIDR                 Allowed CIDR for access (default: 0.0.0.0/0)"
    echo "  -s, --stack-name NAME           CloudFormation stack name (default: ollama-deepseek-api)"
    echo "  -h, --help                      Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -k my-key-pair -t t3.xlarge -c 10.0.0.0/8"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--key-pair)
            KEY_PAIR_NAME="$2"
            shift 2
            ;;
        -t|--instance-type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        -c|--cidr)
            ALLOWED_CIDR="$2"
            shift 2
            ;;
        -s|--stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$KEY_PAIR_NAME" ]; then
    echo -e "${RED}Error: Key pair name is required${NC}"
    print_usage
    exit 1
fi

echo -e "${GREEN}Deploying Ollama DeepSeek API to EC2...${NC}"
echo "Stack Name: $STACK_NAME"
echo "Key Pair: $KEY_PAIR_NAME"
echo "Instance Type: $INSTANCE_TYPE"
echo "Allowed CIDR: $ALLOWED_CIDR"
echo ""

# Deploy CloudFormation stack
echo -e "${YELLOW}Creating CloudFormation stack...${NC}"
aws cloudformation deploy \
    --template-file template.yaml \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        KeyPairName="$KEY_PAIR_NAME" \
        InstanceType="$INSTANCE_TYPE" \
        AllowedCIDR="$ALLOWED_CIDR" \
    --capabilities CAPABILITY_IAM

# Get stack outputs
echo -e "${YELLOW}Getting stack outputs...${NC}"
INSTANCE_ID=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' --output text)
PUBLIC_IP=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' --output text)
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' --output text)

echo -e "${GREEN}Stack deployed successfully!${NC}"
echo ""
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "API Endpoint: $API_ENDPOINT"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Wait for the instance to be ready (2-3 minutes)"
echo "2. Copy application files to the instance:"
echo "   scp -i ${KEY_PAIR_NAME}.pem app.js package.json install.sh ubuntu@${PUBLIC_IP}:~/"
echo "3. SSH to the instance and run the installation:"
echo "   ssh -i ${KEY_PAIR_NAME}.pem ubuntu@${PUBLIC_IP}"
echo "   chmod +x install.sh && ./install.sh"
echo "4. Test the API:"
echo "   curl -X POST ${API_ENDPOINT} -H 'Content-Type: application/json' -d '{\"user_message\":\"Hello\"}'"
