import '../entities/repository_config.dart';
import '../repositories/settings_repository.dart';

/// Command input for repository management operations.
sealed class ManageRepositoryCommand {
  /// Creates a command.
  const ManageRepositoryCommand();
}

/// Loads all configured repositories.
class LoadRepositoriesCommand extends ManageRepositoryCommand {
  /// Creates a load command.
  const LoadRepositoriesCommand();
}

/// Adds a repository.
class AddRepositoryCommand extends ManageRepositoryCommand {
  /// Creates an add command.
  const AddRepositoryCommand(this.repository);

  /// Repository to add.
  final RepositoryConfig repository;
}

/// Updates a repository.
class UpdateRepositoryCommand extends ManageRepositoryCommand {
  /// Creates an update command.
  const UpdateRepositoryCommand(this.repository);

  /// Repository to update.
  final RepositoryConfig repository;
}

/// Removes a repository by identifier.
class RemoveRepositoryCommand extends ManageRepositoryCommand {
  /// Creates a remove command.
  const RemoveRepositoryCommand(this.repositoryId);

  /// Repository identifier to remove.
  final String repositoryId;
}

/// Validates a repository by identifier.
class ValidateRepositoryCommand extends ManageRepositoryCommand {
  /// Creates a validation command.
  const ValidateRepositoryCommand(this.repositoryId);

  /// Repository identifier to validate.
  final String repositoryId;
}

/// Result wrapper for repository management operations.
class ManageRepositoryResult {
  /// Creates a command result.
  const ManageRepositoryResult({
    this.repositories = const <RepositoryConfig>[],
    this.validatedRepository,
  });

  /// Current repository collection after command execution.
  final List<RepositoryConfig> repositories;

  /// Updated repository when validation occurs.
  final RepositoryConfig? validatedRepository;
}

/// Executes repository-management commands.
class ManageRepositoryUseCase {
  /// Creates a use case for repository operations.
  const ManageRepositoryUseCase(this._repository);

  final SettingsRepository _repository;

  /// Executes the provided repository command.
  Future<ManageRepositoryResult> call(ManageRepositoryCommand command) async {
    if (command is LoadRepositoriesCommand) {
      final List<RepositoryConfig> repositories = await _repository
          .getRepositories();
      return ManageRepositoryResult(repositories: repositories);
    }

    if (command is AddRepositoryCommand) {
      final List<RepositoryConfig> repositories = await _repository
          .addRepository(command.repository);
      return ManageRepositoryResult(repositories: repositories);
    }

    if (command is UpdateRepositoryCommand) {
      final List<RepositoryConfig> repositories = await _repository
          .updateRepository(command.repository);
      return ManageRepositoryResult(repositories: repositories);
    }

    if (command is RemoveRepositoryCommand) {
      final List<RepositoryConfig> repositories = await _repository
          .removeRepository(command.repositoryId);
      return ManageRepositoryResult(repositories: repositories);
    }

    if (command is ValidateRepositoryCommand) {
      final RepositoryConfig validatedRepository = await _repository
          .validateRepository(command.repositoryId);
      return ManageRepositoryResult(
        repositories: const <RepositoryConfig>[],
        validatedRepository: validatedRepository,
      );
    }

    throw UnsupportedError('Unsupported repository command: $command');
  }
}
