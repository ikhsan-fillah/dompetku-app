enum ResourceStatus { idle, loading, success, empty, error }

class ResourceState<T> {
  const ResourceState._({required this.status, this.data, this.message});

  const ResourceState.idle() : this._(status: ResourceStatus.idle);
  const ResourceState.loading() : this._(status: ResourceStatus.loading);
  const ResourceState.success(T data)
    : this._(status: ResourceStatus.success, data: data);
  const ResourceState.empty() : this._(status: ResourceStatus.empty);
  const ResourceState.error(String message)
    : this._(status: ResourceStatus.error, message: message);

  final ResourceStatus status;
  final T? data;
  final String? message;
}
