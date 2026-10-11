actor OpenNotificationSettingsSpy {

    private(set) var callCount = 0

    func callAsFunction() {
        callCount += 1
    }

}
