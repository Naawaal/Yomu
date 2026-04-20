package com.example.yomu.source

/** Maps runtime execution values to bridge-safe payloads for Flutter MethodChannel. */
class SourceBridgePayloadMapper {
  /** Converts one runtime result into a map payload expected by Flutter bridge client. */
  fun toRuntimePagePayload(result: RuntimeExecutionResult): Map<String, Any?> {
    return mapOf(
      "sourceId" to result.sourceId,
      "items" to result.items.map { item ->
        mapOf(
          "id" to item.id,
          "sourceId" to result.sourceId,
          "title" to item.title,
          "subtitle" to item.subtitle,
          "thumbnailUrl" to item.thumbnailUrl,
        )
      },
      "hasMore" to result.hasMore,
      "nextPage" to result.nextPage,
      "nextPageToken" to result.nextPageToken,
      "operation" to result.operation.value,
      "page" to result.page,
      "pageSize" to result.pageSize,
      "query" to result.query,
    )
  }
}
