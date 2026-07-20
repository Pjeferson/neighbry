// Achata o envelope jsonapi-serializer ({ data: { id, type, attributes } })
// num objeto único { id, ...attributes } — o backend usa jsonapi-serializer
// pra todo recurso de domínio, então isso é reaproveitado por todo módulo
// futuro, não só CommonArea.
interface JsonApiResource<Attributes> {
  id: string;
  type: string;
  attributes: Attributes;
}

interface JsonApiDocument<Attributes> {
  data: JsonApiResource<Attributes>;
}

interface JsonApiCollectionDocument<Attributes> {
  data: JsonApiResource<Attributes>[];
}

export function unwrapResource<Attributes>(
  doc: JsonApiDocument<Attributes>
): Attributes & { id: string } {
  return { id: doc.data.id, ...doc.data.attributes };
}

export function unwrapCollection<Attributes>(
  doc: JsonApiCollectionDocument<Attributes>
): (Attributes & { id: string })[] {
  return doc.data.map((resource) => ({ id: resource.id, ...resource.attributes }));
}
