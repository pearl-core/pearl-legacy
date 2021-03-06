
class PearlError(RuntimeError):
    def __init__(self, message, exit_status):
        super().__init__(message)
        self.exit_status = exit_status


class HookFunctionError(PearlError):
    def __init__(self, message):
        super().__init__(message, 101)


class RepoDoesNotExistError(PearlError):
    def __init__(self, message):
        super().__init__(message, 105)


class PackageNotInRepoError(PearlError):
    def __init__(self, message):
        super().__init__(message, 104)


class PackageAlreadyInstalledError(PearlError):
    def __init__(self, message):
        super().__init__(message, 102)


class PackageNotInstalledError(PearlError):
    def __init__(self, message):
        super().__init__(message, 103)
