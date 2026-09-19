// Expo 기본 Metro 설정.
// firebase 패키지의 react-native 조건부 export 해석을 위해 package exports 를 켠 상태로 유지한다.
const { getDefaultConfig } = require('expo/metro-config');

/** @type {import('expo/metro-config').MetroConfig} */
const config = getDefaultConfig(__dirname);

config.resolver.unstable_enablePackageExports = true;
config.resolver.unstable_conditionNames = ['react-native', 'browser', 'require', 'import'];

module.exports = config;
