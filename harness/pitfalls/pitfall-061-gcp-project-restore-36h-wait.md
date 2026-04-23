---
name: GCP 프로젝트 복원 후 36시간 전파 대기
description: 프로젝트 undelete 직후 Cloud Run/Artifact Registry/App Hosting 전부 실패 — Google 공식 "최대 36시간" 전파 대기 필요
type: pitfall
tags: [gcp, project-restore, cloud-run, artifact-registry, app-hosting, propagation]
---

# pitfall-061: GCP 프로젝트 복원 후 36시간 전파 대기

## 증상 (Symptom)

프로젝트를 `gcloud projects undelete` 또는 Firebase Console에서 복원한 직후:

1. **Firebase App Hosting rollout**:
   `ArgoAdminNoCloudAudit.CreateBuild PERMISSION_DENIED` + `EndUserCredsRequested`

2. **Cloud Run 신규 서비스 생성**:
   `The service has encountered an internal error`
   - Revision은 `ConfigurationsReady: True`로 정상 생성
   - `RoutesReady: False`로 Route만 실패 (URL 할당 안 됨)

3. **Artifact Registry push**:
   `denied: Project #{number} has been deleted`
   - 새 repository 생성도 `Requested entity was not found` 실패

4. **기존 리소스는 정상 동작** (복원 이전 생성된 Cloud Run 서비스, Artifact Registry repo 등)

## 원인 (Root Cause)

**Google 공식 문서 명시**: 프로젝트 복원 후 일부 서비스는 정상 동작하기까지 **최대 36시간** 소요.

- [Delete and restore projects](https://cloud.google.com/resource-manager/docs/delete-restore-projects): "Some services may take up to 36 hours to fully resume operations."
- 복원 직후 Google 내부 서비스들(ArgoAdmin/Cloud Run Routes controller/Artifact Registry 등)의 "project deleted" 캐시가 전파되지 않은 상태
- IAM은 정상, 서비스 아이덴티티도 정상, 하지만 **내부 resource registry 캐시만 stale**

## 증상별 확인 체크포인트

| 지표 | 확인 명령 |
|------|----------|
| 복원 시각 | `gcloud logging read 'protoPayload.methodName:"UndeleteProject"' --format="value(timestamp)"` |
| 경과 시간 | 현재 UTC - 복원 UTC |
| Route 상태 | `curl .../services/{name} \| jq '.status.conditions'` (RoutesReady 확인) |

## 해결 (Solution)

### 1순위: 기다리기 (0-36시간)

- 공식 정책에 따라 **36시간 내 자동 복구**
- CLI/API로 해결 불가 (웹 검색 없이 Support 필요라 단정하지 말 것)
- 대기 중 로컬 개발/커밋/GitHub push는 정상 가능

### 2순위: Google Cloud Support (36시간 후에도 미복구 시)

- 프로젝트 ID, 복원 시각, 실패 로그 포함하여 케이스 생성
- 엔지니어가 내부 resource cache 수동 리셋

### 우회 시도가 **불가능**한 것 (시간 낭비 금지)

- ❌ 서비스 아이덴티티 재생성
- ❌ IAM 역할 재부여 (이미 정상)
- ❌ API disable/re-enable
- ❌ 백엔드/서비스 삭제 후 재생성
- ❌ 다른 region 시도
- ❌ `gcloud run services replace` Knative YAML
- ❌ `managedResources` PATCH (시스템 관리 필드)

## 재발 방지 (Prevention)

1. **프로젝트 삭제 전 확인**: "정말 이 프로젝트? 다른 거 아님?" 두 번 확인
2. **복원 직후 대기 원칙**: `UndeleteProject` 로그 시각 + 36시간 전까지는 deploy 시도 금지
3. **막히면 웹 검색 먼저**: "못 고친다" 단정 전 반드시 공식 문서/포럼 확인
   - 특히 Google 서비스의 "internal error"는 대부분 문서화된 동작
4. **기존 서비스 격리**: 복원 후 기존 서비스(calendar-web 등)는 정상이므로 임의로 재배포 시도 금지 (망칠 수 있음)

## 재발 이력

- 2026-04-22 (최초 발견): `ai-project-ce41f` 복원. 저자가 "Support만 해결 가능" 잘못 단정.
  대표님 지적으로 웹 검색 → 36시간 정책 발견.

## 참조

- [Google Docs: Delete and restore projects](https://cloud.google.com/resource-manager/docs/delete-restore-projects)
- [Google Docs: gcloud projects undelete](https://cloud.google.com/sdk/gcloud/reference/projects/undelete)
- Forum: [Cloud Run internal error after restoration (discuss.google.dev/t/135911)](https://discuss.google.dev/t/cloud-run-fails-to-deploy-the-service-has-encountered-an-internal-error/135911)
