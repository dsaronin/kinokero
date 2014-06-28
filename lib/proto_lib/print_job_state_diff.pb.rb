## Generated from print_job_state_diff.proto for 
require "beefcake"


class PrintJobStateDiff
  include Beefcake::Message
end

class PrintJobStateDiff
  optional :state, JobState, 1
  optional :pages_printed, :int32, 2
end
