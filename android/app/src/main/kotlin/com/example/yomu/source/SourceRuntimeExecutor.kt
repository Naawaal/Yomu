package com.example.yomu.source

import java.util.concurrent.CancellationException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutionException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import java.util.concurrent.atomic.AtomicLong

/** Executes source runtime requests with timeout and cooperative cancellation. */
class SourceRuntimeExecutor(
  private val timeoutMs: Long = DEFAULT_TIMEOUT_MS,
  private val executor: ExecutorService = Executors.newFixedThreadPool(DEFAULT_POOL_SIZE),
) {
  private val requestIds = ConcurrentHashMap<String, AtomicLong>()
  private val running = ConcurrentHashMap<String, Future<RuntimeExecutionResult>>()

  /** Executes one runtime request and returns a typed page-like result. */
  fun execute(request: RuntimeExecutionRequest): RuntimeExecutionResult {
    val operationKey = operationKey(request)
    val requestId = nextRequestId(operationKey)

    running.remove(operationKey)?.cancel(true)

    val future = executor.submit<RuntimeExecutionResult> {
      if (!isCurrentRequest(operationKey, requestId)) {
        throw RuntimeExecutionException(
          code = ErrorCode.runtimeCancelled,
          message = "Runtime execution was cancelled before start.",
        )
      }

      // TODO: TODO-004 follow-up should replace this stub with extension runtime invocation.
      RuntimeExecutionResult(
        sourceId = request.sourceId,
        items = emptyList(),
        hasMore = false,
        nextPage = null,
        nextPageToken = null,
        operation = request.operation,
        page = request.page,
        pageSize = request.pageSize,
        query = request.query,
      )
    }

    running[operationKey] = future

    try {
      val result = future.get(timeoutMs, TimeUnit.MILLISECONDS)
      if (!isCurrentRequest(operationKey, requestId)) {
        throw RuntimeExecutionException(
          code = ErrorCode.runtimeCancelled,
          message = "Runtime execution result was superseded by a newer request.",
        )
      }

      return result
    } catch (_: TimeoutException) {
      future.cancel(true)
      throw RuntimeExecutionException(
        code = ErrorCode.runtimeTimeout,
        message = "Runtime execution timed out after ${timeoutMs}ms.",
      )
    } catch (_: CancellationException) {
      throw RuntimeExecutionException(
        code = ErrorCode.runtimeCancelled,
        message = "Runtime execution was cancelled.",
      )
    } catch (exception: InterruptedException) {
      Thread.currentThread().interrupt()
      throw RuntimeExecutionException(
        code = ErrorCode.runtimeCancelled,
        message = "Runtime execution was interrupted.",
        cause = exception,
      )
    } catch (exception: ExecutionException) {
      val cause = exception.cause
      if (cause is RuntimeExecutionException) {
        throw cause
      }

      throw RuntimeExecutionException(
        code = ErrorCode.runtimeExecutionFailed,
        message = cause?.message ?: "Runtime execution failed.",
        cause = cause ?: exception,
      )
    } finally {
      running.remove(operationKey, future)
    }
  }

  private fun operationKey(request: RuntimeExecutionRequest): String {
    return "${request.sourceId}:${request.operation.value}"
  }

  private fun nextRequestId(key: String): Long {
    return requestIds.getOrPut(key) { AtomicLong(0L) }.incrementAndGet()
  }

  private fun isCurrentRequest(key: String, requestId: Long): Boolean {
    return requestIds[key]?.get() == requestId
  }

  companion object {
    const val DEFAULT_TIMEOUT_MS: Long = 15_000L
    const val DEFAULT_POOL_SIZE = 2
  }
}

/** Immutable request input used by [SourceRuntimeExecutor]. */
data class RuntimeExecutionRequest(
  val sourceId: String,
  val operation: RuntimeOperation,
  val page: Int,
  val pageSize: Int,
  val query: String?,
)

/** Immutable page-like runtime result returned by [SourceRuntimeExecutor]. */
data class RuntimeExecutionResult(
  val sourceId: String,
  val items: List<RuntimeMangaItem>,
  val hasMore: Boolean,
  val nextPage: Int?,
  val nextPageToken: String?,
  val operation: RuntimeOperation,
  val page: Int,
  val pageSize: Int,
  val query: String?,
)

/** Lightweight manga item produced by runtime execution. */
data class RuntimeMangaItem(
  val id: String,
  val title: String,
  val subtitle: String?,
  val thumbnailUrl: String?,
)

/** Runtime operation supported by bridge execution calls. */
enum class RuntimeOperation(val value: String) {
  latest("latest"),
  popular("popular"),
  search("search"),
}

/** Runtime execution failure with stable bridge-facing error code. */
class RuntimeExecutionException(
  val code: String,
  override val message: String,
  override val cause: Throwable? = null,
) : RuntimeException(message, cause)

/** Stable runtime error codes shared across host bridge paths. */
object ErrorCode {
  const val runtimeTimeout = "RUNTIME_TIMEOUT"
  const val runtimeCancelled = "RUNTIME_CANCELLED"
  const val runtimeExecutionFailed = "RUNTIME_EXECUTION_FAILED"
}
