#!/bin/bash

# Firebase Storage CORS 설정 스크립트
# 사용법: ./apply_cors.sh [PROJECT_ID]

set -e  # 에러 발생 시 스크립트 중단

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 프로젝트 ID 설정
PROJECT_ID="${1:-military-tracker-96bdd}"
BUCKET_NAME="${PROJECT_ID}.appspot.com"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Firebase Storage CORS 설정${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Google Cloud SDK 설치 확인
echo -e "${YELLOW}⚙️  Google Cloud SDK 확인 중...${NC}"
if ! command -v gsutil &> /dev/null; then
    echo -e "${RED}❌ gsutil이 설치되어 있지 않습니다.${NC}"
    echo -e "${YELLOW}📥 Google Cloud SDK를 설치하세요:${NC}"
    echo -e "   brew install --cask google-cloud-sdk"
    echo -e "   또는 https://cloud.google.com/sdk/docs/install 참고"
    exit 1
fi
echo -e "${GREEN}✅ gsutil 설치 확인됨${NC}"
echo ""

# Google Cloud 인증
echo -e "${YELLOW}🔐 Google Cloud 인증 중...${NC}"
gcloud auth login
echo -e "${GREEN}✅ 인증 완료${NC}"
echo ""

# 프로젝트 설정
echo -e "${YELLOW}📦 프로젝트 설정 중...${NC}"
echo -e "   프로젝트 ID: ${PROJECT_ID}"
echo -e "   버킷 이름: ${BUCKET_NAME}"
gcloud config set project $PROJECT_ID
echo -e "${GREEN}✅ 프로젝트 설정 완료${NC}"
echo ""

# CORS 파일 확인
if [ ! -f "cors.json" ]; then
    echo -e "${RED}❌ cors.json 파일을 찾을 수 없습니다.${NC}"
    exit 1
fi

echo -e "${YELLOW}📄 CORS 설정 파일 내용:${NC}"
cat cors.json
echo ""

# CORS 설정 적용
echo -e "${YELLOW}🌐 CORS 설정 적용 중...${NC}"
if gsutil cors set cors.json gs://$BUCKET_NAME; then
    echo -e "${GREEN}✅ CORS 설정 적용 완료${NC}"
else
    echo -e "${RED}❌ CORS 설정 적용 실패${NC}"
    exit 1
fi
echo ""

# CORS 설정 확인
echo -e "${YELLOW}🔍 적용된 CORS 설정 확인:${NC}"
gsutil cors get gs://$BUCKET_NAME
echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   ✨ CORS 설정 완료!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}💡 다음 단계:${NC}"
echo -e "   1. 브라우저 캐시 삭제"
echo -e "   2. 개발 서버 재시작"
echo -e "   3. 애플리케이션 새로고침"
echo -e "   4. 이미지 업로드/조회 테스트"
echo ""
