/// Returns true if both URLs share the same scheme, host, and port,
/// ignoring path, query, and fragment differences.
bool urlHostsMatch(String? url1, String? url2) {
  if (url1 == null || url1.isEmpty || url2 == null || url2.isEmpty) {
    return false;
  }
  final uri1 = Uri.tryParse(url1);
  final uri2 = Uri.tryParse(url2);
  if (uri1 == null || uri2 == null) return false;
  return uri1.scheme.toLowerCase() == uri2.scheme.toLowerCase() &&
      uri1.host.toLowerCase() == uri2.host.toLowerCase() &&
      uri1.port == uri2.port;
}
