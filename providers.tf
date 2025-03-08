
provider "aws" {
  region = "ap-northeast-1"  # 東京リージョン
  alias  = "tokyo"
}

provider "aws" {
  region = "us-east-1"  # バージニアリージョン（CloudFront証明書用）
  alias  = "virginia"
}

# CloudFront用のプロバイダー設定
provider "aws" {
  region = "us-east-1"  # CloudFrontはグローバルサービスだがus-east-1を使用
  alias  = "global"
}

# デフォルトプロバイダー
provider "aws" {
  region = "ap-northeast-1"  # デフォルトリージョン
}
