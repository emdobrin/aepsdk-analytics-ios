/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPServices
import AEPIdentity
import Foundation

/// This class encapsulates the analytics config properties used across the analytics handlers.
/// These properties are retrieved from the shared states.
class AnalyticsState {
    private let LOG_TAG = "AnalyticsState"
    /// Instance of `AnalyticsRequestSerializer`, use to serialize visitor id's List.
    private let analyticsRequestSerializer = AnalyticsRequestSerializer()
    /// `Offline enabled` configuration setting. If true analytics hits are queued when device is offline and sent when device is online.
    private(set) var offlineEnabled: Bool = AnalyticsConstants.Default.OFFLINE_ENABLED
    /// `Batch limit` configuration setting. Number of hits to queue before sending to Analytics.
    private(set) var batchLimit: Int = AnalyticsConstants.Default.BATCH_LIMIT
    /// Holds the value for privacy status opted by the user.
    private(set) var privacyStatus: PrivacyStatus = AnalyticsConstants.Default.PRIVACY_STATUS
    /// `Launch hit delay` configuration setting. Number of seconds to wait before Analytics launch hits are sent.
    private(set) var launchHitDelay: TimeInterval = AnalyticsConstants.Default.LAUNCH_HIT_DELAY
    /// `Backdate Previous Session Info` configuration setting. If enable backdates session information hits.
    private(set) var backDateSessionInfoEnabled: Bool = AnalyticsConstants.Default.BACKDATE_SESSION_INFO_ENABLED
    /// Id for `Marketing cloud organization`.
    private(set) var marketingCloudOrganizationId: String?

    #if DEBUG
        var analyticForwardingEnabled: Bool = AnalyticsConstants.Default.FORWARDING_ENABLED
        var marketingCloudId: String?
        var locationHint: String?
        var blob: String?
        var rsids: String?
        var host: String?
        var defaultData: [String: String] = [String: String]()
        var lifecycleMaxSessionLength: TimeInterval = AnalyticsConstants.Default.LIFECYCLE_MAX_SESSION_LENGTH
        var lifecycleSessionStartTimestamp: TimeInterval = AnalyticsConstants.Default.LIFECYCLE_SESSION_START_TIMESTAMP
        var orgId: String?
    #else
        /// Configuration setting for forwarding Analytics hits to Audience manager.
        private(set) var analyticForwardingEnabled: Bool = AnalyticsConstants.Default.FORWARDING_ENABLED
        /// Unique id for device.
        private(set) var marketingCloudId: String?
        /// The location hint value.
        private var locationHint: String?
        /// The blob value.
        private var blob: String?
        /// `RSID` configuration settings. Id of report suites to which data should be send.
        private(set) var rsids: String?
        /// Analytics Server url.
        private(set) var host: String?
        private(set) var defaultData: [String: String] = [:]
        /// Maximum time in seconds before a session times out.
        private(set) var lifecycleMaxSessionLength: TimeInterval = AnalyticsConstants.Default.LIFECYCLE_MAX_SESSION_LENGTH
        /// Start timestamp of new session.
        private(set) var lifecycleSessionStartTimestamp: TimeInterval = AnalyticsConstants.Default.LIFECYCLE_SESSION_START_TIMESTAMP
        /// The Experience Cloud Org ID provided by the Configuration extension.
        private(set) var orgId: String?
    #endif
    /// A serialized form of list of visitor identifiers.
    private(set) var serializedVisitorIdsList: String?
    /// Stores the Application name and version.
    private(set) var applicationId: String?
    /// The value of advertising identifier.
    private(set) var advertisingId: String?
    /// Whether or not Assurance session is active.
    private(set) var assuranceSessionActive: Bool?
    /// Typealias for Lifecycle Event Data keys.
    private typealias LifeCycleEventDataKeys = AnalyticsConstants.Lifecycle.EventDataKeys
    /// Typealias for Configuration Event Data keys.
    private typealias ConfigurationEventDataKeys = AnalyticsConstants.Configuration.EventDataKeys
    /// Typealias for Identity Event Data keys.
    private typealias IdentityEventDataKeys = AnalyticsConstants.Identity.EventDataKeys
    /// Typealias for Places Event Data keys.
    private typealias PlacesEventDataKeys = AnalyticsConstants.Places.EventDataKeys
    /// Typealias for Assurance Event Data keys.
    private typealias AssuranceEventDataKeys = AnalyticsConstants.Assurance.EventDataKeys

    /// Initializer that takes the shared states map and initialize the properties.
    /// - Parameter dataMap: The map contains the shared state data required by the Analytics SDK.
    init(dataMap: [String: [String: Any]?]) {
        for key in dataMap.keys {
            guard let sharedState = dataMap[key] else {
                continue
            }
            switch key {
            case ConfigurationEventDataKeys.SHARED_STATE_NAME:
                extractConfigurationInfo(from: sharedState)
            case LifeCycleEventDataKeys.SHARED_STATE_NAME:
                extractLifecycleInfo(from: sharedState)
            case IdentityEventDataKeys.SHARED_STATE_NAME:
                extractIdentityInfo(from: sharedState)
            case PlacesEventDataKeys.SHARED_STATE_NAME:
                extractPlacesInfo(from: sharedState)
            case AssuranceEventDataKeys.SHARED_STATE_NAME:
                extractAssuranceInfo(from: sharedState)
            default:
                break
            }
        }
    }

    /// Extracts the configuration data from the provided shared state data.
    /// - Parameter configurationData the data map from `Configuration` shared state.
    func extractConfigurationInfo(from configurationData: [String: Any]?) {
        guard let configurationData = configurationData else {
            Log.trace(label: LOG_TAG, "ExtractConfigurationInfo - Failed to extract configuration data (event data was null).")
            return
        }
        host = configurationData[ConfigurationEventDataKeys.ANALYTICS_SERVER] as? String
        rsids = configurationData[ConfigurationEventDataKeys.ANALYTICS_REPORT_SUITES] as? String
        analyticForwardingEnabled = configurationData[ConfigurationEventDataKeys.ANALYTICS_AAMFORWARDING] as? Bool ?? AnalyticsConstants.Default.FORWARDING_ENABLED
        offlineEnabled = configurationData[ConfigurationEventDataKeys.ANALYTICS_OFFLINE_TRACKING] as? Bool ?? AnalyticsConstants.Default.OFFLINE_ENABLED
        batchLimit = configurationData[ConfigurationEventDataKeys.ANALYTICS_BATCH_LIMIT] as? Int ?? AnalyticsConstants.Default.BATCH_LIMIT
        launchHitDelay =  TimeInterval.init(configurationData[ConfigurationEventDataKeys.ANALYTICS_LAUNCH_HIT_DELAY] as? Double ?? AnalyticsConstants.Default.LAUNCH_HIT_DELAY)
        marketingCloudOrganizationId = configurationData[ConfigurationEventDataKeys.MARKETING_CLOUD_ORGID_KEY] as? String
        backDateSessionInfoEnabled = configurationData[ConfigurationEventDataKeys.ANALYTICS_BACKDATE_PREVIOUS_SESSION] as? Bool ?? AnalyticsConstants.Default.BACKDATE_SESSION_INFO_ENABLED
        privacyStatus = PrivacyStatus.init(rawValue: configurationData[ConfigurationEventDataKeys.GLOBAL_PRIVACY] as? PrivacyStatus.RawValue ?? AnalyticsConstants.Default.PRIVACY_STATUS.rawValue) ?? AnalyticsConstants.Default.PRIVACY_STATUS
    }

    /// Extracts the `Lifecycle` data from the provided shared state data.
    /// - Parameter lifecycleData the data map from `Lifecycle` shared state.
    func extractLifecycleInfo(from lifecycleData: [String: Any]?) {
        guard let lifecycleData = lifecycleData else {
            Log.trace(label: LOG_TAG, "ExtractLifecycleInfo - Failed to extract lifecycle data (event data was null).")
            return
        }
        if let lifecycleSessionStartTime = lifecycleData[LifeCycleEventDataKeys.SESSION_START_TIMESTAMP] as? TimeInterval {
            lifecycleSessionStartTimestamp = lifecycleSessionStartTime
        }
        if let lifecycleMaxSessionLen = lifecycleData[LifeCycleEventDataKeys.MAX_SESSION_LENGTH] as? TimeInterval {
            lifecycleMaxSessionLength = lifecycleMaxSessionLen
        }
        if let lifecyleContextData = lifecycleData[LifeCycleEventDataKeys.LIFECYCLE_CONTEXT_DATA] as? [String: String] {
            if let operatingSystem = lifecyleContextData[LifeCycleEventDataKeys.OPERATING_SYSTEM] {
                defaultData[AnalyticsConstants.ContextDataKeys.OPERATING_SYSTEM] = operatingSystem
            }
            if let deviceName = lifecyleContextData[LifeCycleEventDataKeys.DEVICE_NAME] {
                defaultData[AnalyticsConstants.ContextDataKeys.DEVICE_NAME] = deviceName
            }
            if let deviceResolution = lifecyleContextData[LifeCycleEventDataKeys.DEVICE_RESOLUTION] {
                defaultData[AnalyticsConstants.ContextDataKeys.DEVICE_RESOLUTION] = deviceResolution
            }
            if let carrierName = lifecyleContextData[LifeCycleEventDataKeys.CARRIER_NAME] {
                defaultData[AnalyticsConstants.ContextDataKeys.CARRIER_NAME] = carrierName
            }
            if let runMode = lifecyleContextData[LifeCycleEventDataKeys.RUN_MODE] {
                defaultData[AnalyticsConstants.ContextDataKeys.RUN_MODE] = runMode
            }
            if let applicationId = lifecyleContextData[LifeCycleEventDataKeys.APP_ID] {
                defaultData[AnalyticsConstants.ContextDataKeys.APPLICATION_IDENTIFIER] = applicationId
            }
        }
    }

    /// Extracts the `Identity` data from the provided shared state data.
    /// - Parameter identityData the data map from `Identity` shared state.
    func extractIdentityInfo(from identityData: [String: Any]?) {
        guard let identityData = identityData else {
            Log.trace(label: LOG_TAG, "ExtractIdentityInfo - Failed to extract identity data (event data was null).")
            return
        }
        if let marketingCloudId = identityData[IdentityEventDataKeys.VISITOR_ID_MID] as? String {
            self.marketingCloudId = marketingCloudId
        }
        if let blob = identityData[IdentityEventDataKeys.VISITOR_ID_BLOB] as? String {
            self.blob = blob
        }
        if let locationHint = identityData[IdentityEventDataKeys.VISITOR_ID_LOCATION_HINT] as? String {
            self.locationHint = locationHint
        }
        if let advertisingId = identityData[IdentityEventDataKeys.ADVERTISING_IDENTIFIER] as? String {
            self.advertisingId = advertisingId
        }
        if let identifiableArray = identityData[IdentityEventDataKeys.VISITOR_IDS_LIST] as? [Identifiable] {
            serializedVisitorIdsList = analyticsRequestSerializer.generateAnalyticsCustomerIdString(from: identifiableArray)
        }
    }

    /// Extracts the `Places` data from the provided shared state data.
    /// - Parameter placesData the data map from `Places` shared state.
    func extractPlacesInfo(from placesData: [String: Any]?) {
        guard let placesData = placesData else {
            Log.trace(label: LOG_TAG, "ExtractPlacesInfo - Failed to extract places data (event data was null).")
            return
        }
        if let placesContextData = placesData[PlacesEventDataKeys.CURRENT_POI] as? [String: String] {
            if let regionId = placesContextData[PlacesEventDataKeys.REGION_ID] {
                defaultData[AnalyticsConstants.ContextDataKeys.REGION_ID] = regionId
            }
            if let regionName = placesContextData[PlacesEventDataKeys.REGION_NAME] {
                defaultData[AnalyticsConstants.ContextDataKeys.REGION_NAME] = regionName
            }
        }
    }

    /// Extracts the `Assurance` data from the provided shared state data.
    /// - Parameter assuranceData the data map from `Assurance` shared state.
    func extractAssuranceInfo(from assuranceData: [String: Any]?) {
        guard let assuranceData = assuranceData else {
            Log.trace(label: LOG_TAG, "ExtractAssuranceInfo - Failed to extract Assurance data (event data was null).")
            return
        }
        if let assuranceSessionId = assuranceData[AssuranceEventDataKeys.SESSION_ID] as? String {
            assuranceSessionActive = !assuranceSessionId.isEmpty
        }
    }

    /// Extracts the `visitor ID blob`, `locationHint` and `Experience Cloud ID (MID)` in a map if `MID` is not null
    /// - Returns: the resulted map or an empty map if MID is null.
    func getAnalyticsIdVisitorParameters() -> [String: String] {
        var analyticsIdVisitorParameters = [String: String]()
        guard let marketingCloudId = marketingCloudId, !marketingCloudId.isEmpty else {
            return analyticsIdVisitorParameters
        }
        analyticsIdVisitorParameters[AnalyticsConstants.ParameterKeys.KEY_MID] = marketingCloudId
        if let blob = blob, !blob.isEmpty {
            analyticsIdVisitorParameters[AnalyticsConstants.ParameterKeys.KEY_BLOB] = blob
        }
        if let locationHint = locationHint, !locationHint.isEmpty {
            analyticsIdVisitorParameters[AnalyticsConstants.ParameterKeys.KEY_LOCATION_HINT] = locationHint
        }
        return analyticsIdVisitorParameters
    }

    /// Check if `rsids` and `tracking server` is configure for analytics module.
    /// - Returns: true of both conditions are met false otherwise.
    func isAnalyticsConfigured() -> Bool {
        return !(rsids?.isEmpty ?? true) && !(host?.isEmpty ?? true)
    }

    /// Creates and returns the base url for analytics requests.
    /// - Parameter sdkVersion: the version of the SDK.
    /// - Returns the base URL for an Analytics request.
    func getBaseUrl(sdkVersion: String) -> URL? {
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        urlComponent.host = host
        urlComponent.path = "/b/ss/\(rsids ?? "")/\(getAnalyticsResponseType())/\(sdkVersion)/s"
        guard let url = urlComponent.url else {
            Log.debug(label: LOG_TAG, "Error in creating Analytics base URL.")
            return nil
        }
        return url
    }

    /// Creates a new Analytics ID Request URL
    /// - Parameters:
    ///   - properties: the analytics properties
    func buildAnalyticsIdRequestURL(properties: AnalyticsProperties?) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "id"
        components.queryItems = getMarketingCloudIdQueryParameters()

        guard let url = components.url else {
            Log.error(label: LOG_TAG, "Building Analytics Identity Request URL failed, returning nil.")
            return nil
        }
        return url
    }

    private func getMarketingCloudIdQueryParameters() -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        if marketingCloudId == nil {
            return queryItems
        }

        queryItems += [URLQueryItem(name: AnalyticsConstants.ParameterKeys.KEY_MID, value: marketingCloudId)]
        queryItems += [URLQueryItem(name: AnalyticsConstants.ParameterKeys.KEY_ORG, value: orgId)]

        return queryItems
    }

    /// Determines and return whether visitor id service is enabled or not.
    /// - Returns true if enabled else false.
    func isVisitorIdServiceEnabled() -> Bool {
        return !(marketingCloudOrganizationId?.isEmpty ?? true)
    }

    /// Returns the response type for analytics request url on basis of whether aam forwarding is enabled or not.
    /// - Returns 10 if aam forwarding is enabled in configuration else returns 0
    private func getAnalyticsResponseType() -> String {
        return analyticForwardingEnabled ? "10" : "0"
    }

    /// Determines and returns whether user is opted in or not.
    /// - Returns true of user's privacy statues is optedIn else retuerns false.
    func isOptIn() -> Bool {
        return privacyStatus == PrivacyStatus.optedIn
    }
}
