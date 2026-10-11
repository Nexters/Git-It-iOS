import ProjectDescription

extension ExecutionAction {
    public static func restoreModuleMapPermissions(target: TargetReference) -> Self {
        .executionAction(
            title: "Restore Module Map Permissions",
            scriptText: """
                [ -d "$BUILD_DIR" ] || exit 0
                find "$BUILD_DIR" -type f -path '*/Modules/module.modulemap' ! -perm -u+w -exec chmod u+w {} +
                """,
            target: target,
        )
    }
}
