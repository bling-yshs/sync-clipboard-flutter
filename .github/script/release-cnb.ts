/**
 * 发布到 CNB (cnb.cool)
 *
 * 使用方式: npx tsx release-cnb.ts \
 *   --token <CNB_TOKEN> \
 *   --tag <版本标签> \
 *   --changelog <更新日志> \
 *   --files <文件路径1> <文件路径2> ...
 */

import * as fs from 'fs'
import * as path from 'path'

const CNB_API_BASE = 'https://api.cnb.cool'
const CNB_REPO = 'bling-team/sync-clipboard-flutter-action'

interface CreateReleaseResponse {
  id: string
  tag_name: string
  name: string
}

interface AssetUploadUrlResponse {
  upload_url: string
  expires_in_sec: number
  verify_url: string
}

/**
 * 通用请求头
 */
function getHeaders(token: string, contentType = 'application/json'): Record<string, string> {
  return {
    Accept: 'application/json',
    'Content-Type': contentType,
    Authorization: `Bearer ${token}`,
  }
}

/**
 * 解析命令行参数
 */
function parseArgs(): { token: string; tag: string; changelog: string; files: string[] } {
  const args = process.argv.slice(2)
  const result: Record<string, string> = {}
  const files: string[] = []

  let i = 0
  while (i < args.length) {
    const arg = args[i]
    if (arg.startsWith('--')) {
      const key = arg.replace(/^--/, '')
      if (key === 'files') {
        // 收集所有后续的非 -- 开头的参数作为文件
        i++
        while (i < args.length && !args[i].startsWith('--')) {
          files.push(args[i])
          i++
        }
        continue
      } else {
        result[key] = args[i + 1]
        i += 2
      }
    } else {
      i++
    }
  }

  if (!result.token) throw new Error('缺少必须参数: --token')
  if (!result.tag) throw new Error('缺少必须参数: --tag')
  if (!result.changelog) throw new Error('缺少必须参数: --changelog')
  if (files.length === 0) throw new Error('缺少必须参数: --files')

  return {
    token: result.token,
    tag: result.tag,
    changelog: result.changelog,
    files,
  }
}

/**
 * 步骤 1: 创建 Release
 */
async function createRelease(token: string, tag: string, changelog: string): Promise<string> {
  console.log(`\n📦 步骤 1: 创建 Release ${tag}`)

  const url = `${CNB_API_BASE}/${CNB_REPO}/-/releases`
  const body = {
    body: changelog,
    draft: false,
    name: tag,
    make_latest: 'true',
    prerelease: false,
    tag_name: tag,
    target_commitish: 'main',
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: getHeaders(token),
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`创建 Release 失败: ${response.status} ${errorText}`)
  }

  const data = (await response.json()) as CreateReleaseResponse
  console.log(`   ✅ Release 创建成功，ID: ${data.id}`)
  return data.id
}

/**
 * 步骤 2: 获取文件上传 URL
 */
async function getAssetUploadUrl(
  token: string,
  releaseId: string,
  fileName: string,
  fileSize: number
): Promise<AssetUploadUrlResponse> {
  console.log(`\n📤 步骤 2: 获取上传 URL (${fileName})`)

  const url = `${CNB_API_BASE}/${CNB_REPO}/-/releases/${releaseId}/asset-upload-url`
  const body = {
    asset_name: fileName,
    overwrite: true,
    size: fileSize,
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: getHeaders(token),
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`获取上传 URL 失败: ${response.status} ${errorText}`)
  }

  const data = (await response.json()) as AssetUploadUrlResponse
  console.log(`   ✅ 上传 URL: ${data.upload_url}`)
  return data
}

/**
 * 步骤 3: 上传文件
 */
async function uploadFile(token: string, uploadUrl: string, filePath: string): Promise<void> {
  console.log(`\n⬆️  步骤 3: 上传文件 ${path.basename(filePath)}`)

  const fileBuffer = fs.readFileSync(filePath)

  const response = await fetch(uploadUrl, {
    method: 'PUT',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/octet-stream',
      Authorization: `Bearer ${token}`,
    },
    body: fileBuffer,
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`上传文件失败: ${response.status} ${errorText}`)
  }

  console.log(`   ✅ 文件上传成功`)
}

/**
 * 步骤 4: 确认上传
 */
async function confirmUpload(token: string, verifyUrl: string): Promise<void> {
  console.log(`\n✔️  步骤 4: 确认上传`)

  const response = await fetch(verifyUrl, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
    },
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`确认上传失败: ${response.status} ${errorText}`)
  }

  console.log(`   ✅ 上传确认成功`)
}

/**
 * 上传单个文件的完整流程 (步骤 2-4)
 */
async function uploadAsset(token: string, releaseId: string, filePath: string): Promise<void> {
  const fileName = path.basename(filePath)
  const fileSize = fs.statSync(filePath).size

  console.log(`\n${'='.repeat(50)}`)
  console.log(`📁 开始上传: ${fileName} (${(fileSize / 1024 / 1024).toFixed(2)} MB)`)
  console.log(`${'='.repeat(50)}`)

  // 步骤 2: 获取上传 URL
  const uploadInfo = await getAssetUploadUrl(token, releaseId, fileName, fileSize)

  // 步骤 3: 上传文件
  await uploadFile(token, uploadInfo.upload_url, filePath)

  // 步骤 4: 确认上传
  await confirmUpload(token, uploadInfo.verify_url)

  console.log(`\n🎉 ${fileName} 上传完成!`)
}

async function main() {
  console.log('🚀 开始发布到 CNB...')

  const { token, tag, changelog, files } = parseArgs()

  console.log(`   标签: ${tag}`)
  console.log(`   文件数量: ${files.length}`)
  files.forEach((f) => console.log(`   - ${f}`))

  // 检查所有文件是否存在
  for (const filePath of files) {
    if (!fs.existsSync(filePath)) {
      throw new Error(`文件不存在: ${filePath}`)
    }
  }

  // 步骤 1: 创建 Release
  const releaseId = await createRelease(token, tag, changelog)

  // 步骤 2-4: 上传每个文件
  for (const filePath of files) {
    await uploadAsset(token, releaseId, filePath)
  }

  console.log(`\n${'='.repeat(50)}`)
  console.log(`✅ 所有文件发布完成!`)
  console.log(`   Release: https://cnb.cool/${CNB_REPO}/-/releases/${tag}`)
  console.log(`${'='.repeat(50)}`)
}

main().catch((error) => {
  console.error('\n❌ 发布失败:', error.message)
  process.exit(1)
})
