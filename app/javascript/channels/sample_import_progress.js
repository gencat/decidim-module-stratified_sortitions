import consumer from "./consumer"

export default function subscribeSampleImportProgress(sampleImportId, onProgress) {
  return consumer.subscriptions.create(
    { channel: "SampleImportProgressChannel", sample_import_id: sampleImportId },
    {
      received(data) {
        if (onProgress) onProgress(data)
      }
    }
  )
}
