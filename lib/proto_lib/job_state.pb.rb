## Generated from job_state.proto for 
require "beefcake"


class JobState
  include Beefcake::Message

  module Type
    DRAFT = 0
    HELD = 1
    QUEUED = 2
    IN_PROGRESS = 3
    STOPPED = 4
    DONE = 5
    ABORTED = 6
  end

  class UserActionCause
    include Beefcake::Message

    module ActionCode
      CANCELLED = 0
      PAUSED = 1
      OTHER = 100
    end
  end

  class DeviceStateCause
    include Beefcake::Message

    module ErrorCode
      INPUT_TRAY = 0
      MARKER = 1
      MEDIA_PATH = 2
      MEDIA_SIZE = 3
      MEDIA_TYPE = 4
      OTHER = 100
    end
  end

  class DeviceActionCause
    include Beefcake::Message

    module ErrorCode
      DOWNLOAD_FAILURE = 0
      INVALID_TICKET = 1
      PRINT_FAILURE = 2
      OTHER = 100
    end
  end

  class ServiceActionCause
    include Beefcake::Message

    module ErrorCode
      COMMUNICATION_WITH_DEVICE_ERROR = 0
      CONVERSION_ERROR = 1
      CONVERSION_FILE_TOO_BIG = 2
      CONVERSION_UNSUPPORTED_CONTENT_TYPE = 3
      DELIVERY_FAILURE = 11
      EXPIRATION = 14
      FETCH_DOCUMENT_FORBIDDEN = 4
      FETCH_DOCUMENT_NOT_FOUND = 5
      GOOGLE_DRIVE_QUOTA = 15
      INCONSISTENT_JOB = 6
      INCONSISTENT_PRINTER = 13
      PRINTER_DELETED = 12
      REMOTE_JOB_NO_LONGER_EXISTS = 7
      REMOTE_JOB_ERROR = 8
      REMOTE_JOB_TIMEOUT = 9
      REMOTE_JOB_ABORTED = 10
      OTHER = 100
    end
  end
end

class JobState

  class UserActionCause
    optional :action_code, JobState::UserActionCause::ActionCode, 1
  end

  class DeviceStateCause
    optional :error_code, JobState::DeviceStateCause::ErrorCode, 1
  end

  class DeviceActionCause
    optional :error_code, JobState::DeviceActionCause::ErrorCode, 1
  end

  class ServiceActionCause
    optional :error_code, JobState::ServiceActionCause::ErrorCode, 1
  end
  optional :type, JobState::Type, 1
  optional :user_action_cause, JobState::UserActionCause, 2
  optional :device_state_cause, JobState::DeviceStateCause, 3
  optional :device_action_cause, JobState::DeviceActionCause, 4
  optional :service_action_cause, JobState::ServiceActionCause, 5
end
