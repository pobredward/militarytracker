# Firebase Storage CORS 설정 가이드

## 문제 상황
웹 애플리케이션에서 Firebase Storage의 이미지를 불러올 때 CORS(Cross-Origin Resource Sharing) 에러가 발생합니다.

```
Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/v0/b/...' 
from origin 'http://localhost:61958' has been blocked by CORS policy: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## 해결 방법

### 1단계: Google Cloud SDK 설치 확인

먼저 `gsutil` 명령어가 설치되어 있는지 확인합니다.

```bash
gsutil version
```

만약 설치되어 있지 않다면, [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)를 설치하세요.

**macOS 설치:**
```bash
# Homebrew를 사용하는 경우
brew install --cask google-cloud-sdk

# 또는 직접 다운로드
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### 2단계: Google Cloud 인증

```bash
gcloud auth login
```

브라우저가 열리면 Firebase 프로젝트와 연결된 Google 계정으로 로그인합니다.

### 3단계: Firebase 프로젝트 확인

Firebase Console에서 프로젝트 ID를 확인합니다.

```bash
# 프로젝트 설정
gcloud config set project [YOUR_PROJECT_ID]
```

예시:
```bash
gcloud config set project military-tracker-96bdd
```

### 4단계: CORS 설정 적용

프로젝트 루트에 있는 `cors.json` 파일을 사용하여 CORS 설정을 적용합니다.

```bash
gsutil cors set cors.json gs://[YOUR_BUCKET_NAME]
```

**버킷 이름 찾기:**
- Firebase Console > Storage > Files
- URL에서 버킷 이름 확인: `gs://your-project-id.appspot.com`

예시:
```bash
gsutil cors set cors.json gs://military-tracker-96bdd.appspot.com
```

### 5단계: CORS 설정 확인

설정이 올바르게 적용되었는지 확인합니다.

```bash
gsutil cors get gs://[YOUR_BUCKET_NAME]
```

예시:
```bash
gsutil cors get gs://military-tracker-96bdd.appspot.com
```

출력 결과가 `cors.json` 파일의 내용과 일치해야 합니다.

## CORS 설정 파일 설명 (cors.json)

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
  }
]
```

### 설정 옵션:

- **origin**: 요청을 허용할 도메인
  - `"*"`: 모든 도메인 허용 (개발 단계)
  - 프로덕션에서는 특정 도메인만 허용하는 것이 좋습니다:
    ```json
    "origin": ["https://yourdomain.com", "http://localhost:61958"]
    ```

- **method**: 허용할 HTTP 메서드
  - GET: 이미지 읽기
  - PUT/POST: 이미지 업로드
  - DELETE: 이미지 삭제

- **maxAgeSeconds**: 브라우저가 CORS 응답을 캐시하는 시간 (초)

- **responseHeader**: CORS 요청에 포함될 응답 헤더

## 프로덕션 환경 CORS 설정

프로덕션 환경에서는 보안을 위해 특정 도메인만 허용하세요:

```json
[
  {
    "origin": ["https://yourdomain.com"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type"]
  },
  {
    "origin": ["http://localhost:*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
  }
]
```

## 문제 해결

### 1. gsutil 명령어를 찾을 수 없음

```bash
# PATH에 Google Cloud SDK 추가
export PATH=$PATH:~/google-cloud-sdk/bin
source ~/.zshrc  # 또는 ~/.bashrc
```

### 2. 권한 에러

```bash
# 인증 다시 시도
gcloud auth login
gcloud auth application-default login
```

### 3. 프로젝트 접근 권한 없음

Firebase Console에서 사용 중인 Google 계정이 프로젝트의 소유자 또는 편집자 권한을 가지고 있는지 확인하세요.

### 4. CORS 설정 후에도 에러 발생

- 브라우저 캐시 삭제
- 시크릿 모드에서 테스트
- 개발 서버 재시작
- 5-10분 후 재시도 (설정 전파 시간)

## 빠른 적용 스크립트

프로젝트에 CORS를 빠르게 적용하려면:

```bash
#!/bin/bash

# 프로젝트 ID 설정
PROJECT_ID="military-tracker-96bdd"
BUCKET_NAME="${PROJECT_ID}.appspot.com"

# Google Cloud 설정
echo "🔐 Google Cloud 인증 중..."
gcloud auth login

echo "📦 프로젝트 설정 중..."
gcloud config set project $PROJECT_ID

echo "🌐 CORS 설정 적용 중..."
gsutil cors set cors.json gs://$BUCKET_NAME

echo "✅ CORS 설정 확인..."
gsutil cors get gs://$BUCKET_NAME

echo "✨ 완료!"
```

스크립트를 `apply_cors.sh`로 저장하고 실행:

```bash
chmod +x apply_cors.sh
./apply_cors.sh
```

## 참고 문서

- [Firebase Storage CORS 설정](https://firebase.google.com/docs/storage/web/download-files#cors_configuration)
- [Google Cloud Storage CORS](https://cloud.google.com/storage/docs/configuring-cors)
- [gsutil cors 명령어](https://cloud.google.com/storage/docs/gsutil/commands/cors)
