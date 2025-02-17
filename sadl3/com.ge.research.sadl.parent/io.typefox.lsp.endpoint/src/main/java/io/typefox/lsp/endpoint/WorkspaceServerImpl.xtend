package io.typefox.lsp.endpoint

import com.google.common.util.concurrent.ThreadFactoryBuilder
import io.typefox.lsp.endpoint.nio.file.FileManager
import java.io.IOException
import java.net.URI
import java.nio.charset.Charset
import java.nio.file.Path
import java.nio.file.Paths
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import org.apache.log4j.Logger
import org.eclipse.lsp4j.InitializeParams
import org.eclipse.lsp4j.jsonrpc.CompletableFutures
import org.eclipse.lsp4j.jsonrpc.Endpoint
import org.eclipse.lsp4j.jsonrpc.json.JsonRpcMethodProvider
import org.eclipse.lsp4j.jsonrpc.services.ServiceEndpoints
import org.eclipse.lsp4j.services.LanguageClient
import org.eclipse.lsp4j.services.LanguageClientAware
import org.eclipse.lsp4j.services.LanguageServer
import org.eclipse.xtend.lib.annotations.Delegate

import static extension java.nio.file.Files.*
import java.nio.file.Files

class WorkspaceServerImpl implements LanguageServer, LanguageClientAware, JsonRpcMethodProvider, WorkspaceServer, Endpoint {

	val static DELAY = 500

	val static LOGGER = Logger.getLogger(WorkspaceServerImpl)

	val FileManager fileManager

	@Delegate
	val LanguageServer languageServer

	val ScheduledExecutorService executorService

	WorkspaceClient client

	new(LanguageServer languageServer) {
		this.languageServer = languageServer

		this.fileManager = new FileManager
		fileManager.eventEmitter = [
			new DidChangeWatchedFilesEvent [ params |
				languageServer.workspaceService.didChangeWatchedFiles(params)
				client?.didChangeWatchedFiles(params)
			]
		]
		
		val builder = new ThreadFactoryBuilder
		builder.nameFormat = WorkspaceServerImpl.simpleName + ' %d'
		val threadFactory = builder.build
		this.executorService = Executors.newSingleThreadScheduledExecutor(threadFactory)
		executorService.scheduleAtFixedRate([
			try {
				fileManager.processEvents
			} catch (Throwable t) {
				LOGGER.error(t.message, t)
			}
		], DELAY, DELAY, TimeUnit.MILLISECONDS)
	}

	override initialize(InitializeParams params) {
		fileManager.close

		val promise = languageServer.initialize(params)
		val rootPath = params.rootPath
		if (rootPath !== null) {
			promise.thenRunAsync([
				val root = Paths.get(rootPath)
				try {
					fileManager.open(root)
				} catch (IOException e) {
					LOGGER.error("Failed to open file manager for watching: " + root, e)
				}
			], this.executorService)
		}
		return promise
	}

	override createFile(CreateFileParams params) {
		return CompletableFutures.computeAsync [ cancelChecker |
			val path = params.uri.toPath
			val file = fileManager.createFile(path)
			if (file !== null && params.content !== null) {
				path.content = params.content
			}
			return null;
		]
	}

	override createDirectory(CreateDirectoryParams params) {
		return CompletableFutures.computeAsync [ cancelChecker |
			val path = params.uri.toPath
			fileManager.createDirectory(path)
			return null;
		]
	}

	override deleteFile(DeleteFileParams params) {
		return CompletableFutures.computeAsync [ cancelChecker |
			val path = params.uri.toPath
			fileManager.delete(path)
			return null;
		]
	}
	
	override renameFile(RenameFileParams params) {
		return CompletableFutures.computeAsync [ cancelChecker |
			Files.move(params.oldUri.toPath, params.newUri.toPath)
			return null;
		]
	}

	override resolveFile(ResolveFileParams params) {
		return CompletableFutures.computeAsync [ cancelChecker |
			val rootPath = params.uri.toPath
			val maxDepth = params.maxDepth ?: Integer.MAX_VALUE

			val fileAcceptor = new FileAcceptor(cancelChecker)
			fileManager.resolve(rootPath, maxDepth, fileAcceptor)
			return fileAcceptor.rootFile
		]
	}

	override resolveFileContent(ResolveFileContentParams params) {
		return CompletableFutures.computeAsync [ cancelChecker |
			val path = params.uri.toPath
			if (path.regularFile) {
				val charset = Charset.defaultCharset
				val bytes = path.readAllBytes

				val content = new FileContent
				content.value = new String(bytes, charset)
				return content
			}
			return null
		]
	}

	override updateFileContent(UpdateFileContentParams params) {
		return CompletableFutures.computeAsync [ cancelChecker |
			val path = params.uri.toPath
			if (path.regularFile) {
				path.content = params.content
			}
			return null
		]
	}

	protected def void setContent(Path path, FileContent content) {
		val bytes = content.value.bytes
		path.write(bytes)
	}

	protected def Path toPath(String uri) {
		return Paths.get(URI.create(uri))
	}

	override shutdown() {
		fileManager.close

		this.executorService.shutdown()
		languageServer.shutdown
	}

	override exit() {
		this.executorService.shutdownNow
		languageServer.exit
	}

	override connect(LanguageClient client) {
		if (languageServer instanceof LanguageClientAware) {
			languageServer.connect(client)
		}
		if (client instanceof Endpoint) {
			this.client = ServiceEndpoints.toServiceObject(client, WorkspaceClient)
		}
	}

	override supportedMethods() {
		val supportedMethods = ServiceEndpoints.getSupportedMethods(this.class)
		if (languageServer instanceof JsonRpcMethodProvider) {
			supportedMethods.putAll(languageServer.supportedMethods)
		}
		return supportedMethods
	}

	override notify(String method, Object parameter) {
		if (languageServer instanceof Endpoint) {
			languageServer.notify(method, parameter);
		}
	}

	override request(String method, Object parameter) {
		if (languageServer instanceof Endpoint) {
			languageServer.request(method, parameter);
		}
	}

}
