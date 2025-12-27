/**
 * 生成 update.json 文件
 * 用于客户端检查更新
 *
 * 使用方式: npx tsx gen-update.ts --version <版本号> --apk-path <APK路径> --changelog <更新日志>
 */

import * as fs from 'fs'
import * as path from 'path'
import * as crypto from 'crypto'

interface DownloadSource {
  id: string
  name: string
  url: string
}

interface UpdateInfo {
  version: string
  minSupportedVersion: string
  changelog: string
  size: number
  sha256: string
  sources: DownloadSource[]
}

/**
 * 计算文件的 SHA256 哈希值
 */
function calculateSha256(filePath: string): string {
  const fileBuffer = fs.readFileSync(filePath)
  const hashSum = crypto.createHash('sha256')
  hashSum.update(fileBuffer)
  return hashSum.digest('hex')
}

/**
 * 获取文件大小（字节）
 */
function getFileSize(filePath: string): number {
  const stats = fs.statSync(filePath)
  return stats.size
}

/**
 * 解析命令行参数
 */
function parseArgs(): { version: string; apkPath: string; changelog: string; minSupportedVersion: string } {
  const args = process.argv.slice(2)
  const result: Record<string, string> = {}

  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace(/^--/, '')
    const value = args[i + 1]
    result[key] = value
  }

  if (!result.version) {
    throw new Error('缺少必须参数: --version')
  }
  if (!result['apk-path']) {
    throw new Error('缺少必须参数: --apk-path')
  }
  if (!result.changelog) {
    throw new Error('缺少必须参数: --changelog')
  }

  return {
    version: result.version,
    apkPath: result['apk-path'],
    changelog: result.changelog,
    minSupportedVersion: result['min-version'] || '0.0.0', // 默认不强制更新
  }
}

/**
 * 生成下载源列表
 */
function generateSources(version: string, apkFileName: string): DownloadSource[] {
  return [
    {
      id: 'github',
      name: 'GitHub',
      url: `https://github.com/bling-yshs/sync-clipboard-flutter/releases/download/v${version}/${apkFileName}`,
    },
    {
      id: 'cnb',
      name: 'CNB (国内加速)',
      url: `https://cnb.cool/bling-team/sync-clipboard-flutter-action/-/releases/download/v${version}/${apkFileName}`,
    },
  ]
}

async function main() {
  const { version, apkPath, changelog, minSupportedVersion } = parseArgs()

  console.log('📦 正在生成 update.json...')
  console.log(`   版本: ${version}`)
  console.log(`   APK 路径: ${apkPath}`)
  console.log(`   最低支持版本: ${minSupportedVersion}`)

  // 检查 APK 文件是否存在
  if (!fs.existsSync(apkPath)) {
    throw new Error(`APK 文件不存在: ${apkPath}`)
  }

  // 计算 SHA256 和文件大小
  console.log('   计算 SHA256...')
  const sha256 = calculateSha256(apkPath)
  const size = getFileSize(apkPath)
  console.log(`   SHA256: ${sha256}`)
  console.log(`   文件大小: ${size} 字节 (${(size / 1024 / 1024).toFixed(2)} MB)`)

  // 获取 APK 文件名
  const apkFileName = path.basename(apkPath)

  // 生成 update.json 内容
  const updateInfo: UpdateInfo = {
    version,
    minSupportedVersion,
    changelog,
    size,
    sha256,
    sources: generateSources(version, apkFileName),
  }

  // 写入文件
  const outputPath = path.join(path.dirname(apkPath), 'update.json')
  fs.writeFileSync(outputPath, JSON.stringify(updateInfo, null, 2), 'utf-8')
  console.log(`✅ update.json 已生成: ${outputPath}`)

  // 同时输出到控制台用于调试
  console.log('\n📄 update.json 内容:')
  console.log(JSON.stringify(updateInfo, null, 2))
}

main().catch((error) => {
  console.error('❌ 错误:', error.message)
  process.exit(1)
})