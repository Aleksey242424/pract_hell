--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

-- Started on 2026-11-04 22:18:36

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 243 (class 1259 OID 93997)
-- Name: captcha_challenges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.captcha_challenges (
    challenge_id character varying(100) NOT NULL,
    correct_answer character varying(20) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    is_used boolean DEFAULT false NOT NULL
);


ALTER TABLE public.captcha_challenges OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 94001)
-- Name: captcha_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.captcha_tokens (
    token character varying(200) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    is_used boolean DEFAULT false NOT NULL
);


ALTER TABLE public.captcha_tokens OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 93930)
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id_category bigint NOT NULL,
    category_name character varying(100) NOT NULL
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 93929)
-- Name: categories_id_category_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.categories ALTER COLUMN id_category ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.categories_id_category_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 224 (class 1259 OID 93942)
-- Name: counterparties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.counterparties (
    id_counterparty bigint NOT NULL,
    external_id character varying(30),
    name character varying(255) NOT NULL,
    inn character varying(12),
    address text,
    phone character varying(30),
    counterparty_type character varying(20) NOT NULL,
    CONSTRAINT counterparties_counterparty_type_check CHECK (((counterparty_type)::text = ANY (ARRAY[('Покупатель'::character varying)::text, ('Поставщик'::character varying)::text])))
);


ALTER TABLE public.counterparties OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 93941)
-- Name: counterparties_id_counterparty_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.counterparties ALTER COLUMN id_counterparty ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.counterparties_id_counterparty_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 236 (class 1259 OID 93974)
-- Name: customer_order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_order_items (
    id_order_item bigint NOT NULL,
    id_order bigint NOT NULL,
    id_product bigint NOT NULL,
    quantity numeric(14,3) NOT NULL,
    unit_price numeric(14,2) NOT NULL,
    discount_percent numeric(5,2) DEFAULT 0 NOT NULL,
    CONSTRAINT customer_order_items_discount_percent_check CHECK (((discount_percent >= (0)::numeric) AND (discount_percent <= (100)::numeric))),
    CONSTRAINT customer_order_items_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT customer_order_items_unit_price_check CHECK ((unit_price >= (0)::numeric))
);


ALTER TABLE public.customer_order_items OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 93973)
-- Name: customer_order_items_id_order_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.customer_order_items ALTER COLUMN id_order_item ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.customer_order_items_id_order_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 234 (class 1259 OID 93969)
-- Name: customer_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_orders (
    id_order bigint NOT NULL,
    order_number character varying(50) NOT NULL,
    order_date date NOT NULL,
    id_customer bigint NOT NULL,
    status character varying(30) DEFAULT 'Новый'::character varying NOT NULL
);


ALTER TABLE public.customer_orders OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 93968)
-- Name: customer_orders_id_order_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.customer_orders ALTER COLUMN id_order ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.customer_orders_id_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 242 (class 1259 OID 93991)
-- Name: notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    id_user bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.notes OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 93990)
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.notes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 222 (class 1259 OID 93938)
-- Name: product_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_types (
    id_type bigint NOT NULL,
    type_name character varying(100) NOT NULL
);


ALTER TABLE public.product_types OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 93937)
-- Name: product_types_id_type_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.product_types ALTER COLUMN id_type ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.product_types_id_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 240 (class 1259 OID 93986)
-- Name: production_order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.production_order_items (
    id_production_item bigint NOT NULL,
    id_production_order bigint NOT NULL,
    id_product bigint NOT NULL,
    quantity numeric(14,3) NOT NULL,
    CONSTRAINT production_order_items_quantity_check CHECK ((quantity > (0)::numeric))
);


ALTER TABLE public.production_order_items OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 93985)
-- Name: production_order_items_id_production_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.production_order_items ALTER COLUMN id_production_item ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.production_order_items_id_production_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 238 (class 1259 OID 93982)
-- Name: production_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.production_orders (
    id_production_order bigint NOT NULL,
    order_number character varying(50) NOT NULL,
    launch_date date NOT NULL,
    department character varying(150) NOT NULL
);


ALTER TABLE public.production_orders OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 93981)
-- Name: production_orders_id_production_order_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.production_orders ALTER COLUMN id_production_order ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.production_orders_id_production_order_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 226 (class 1259 OID 93949)
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    id_product bigint NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    id_type bigint,
    id_category bigint
);


ALTER TABLE public.products OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 93948)
-- Name: products_id_product_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.products ALTER COLUMN id_product ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.products_id_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 228 (class 1259 OID 93953)
-- Name: resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resources (
    id_resource bigint NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    resource_kind character varying(20) NOT NULL,
    id_unit bigint NOT NULL,
    unit_price numeric(14,2) NOT NULL,
    CONSTRAINT resources_resource_kind_check CHECK (((resource_kind)::text = ANY (ARRAY[('Материал'::character varying)::text, ('Операция'::character varying)::text]))),
    CONSTRAINT resources_unit_price_check CHECK ((unit_price >= (0)::numeric))
);


ALTER TABLE public.resources OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 93952)
-- Name: resources_id_resource_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.resources ALTER COLUMN id_resource ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.resources_id_resource_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 232 (class 1259 OID 93964)
-- Name: specification_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specification_items (
    id_specification_item bigint NOT NULL,
    id_specification bigint NOT NULL,
    id_resource bigint NOT NULL,
    norm_quantity numeric(14,4) NOT NULL,
    CONSTRAINT specification_items_norm_quantity_check CHECK ((norm_quantity > (0)::numeric))
);


ALTER TABLE public.specification_items OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 93963)
-- Name: specification_items_id_specification_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.specification_items ALTER COLUMN id_specification_item ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.specification_items_id_specification_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 230 (class 1259 OID 93959)
-- Name: specifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.specifications (
    id_specification bigint NOT NULL,
    id_product bigint NOT NULL,
    manufacturer character varying(255),
    valid_from date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE public.specifications OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 93958)
-- Name: specifications_id_specification_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.specifications ALTER COLUMN id_specification ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.specifications_id_specification_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 220 (class 1259 OID 93934)
-- Name: units; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.units (
    id_unit bigint NOT NULL,
    metric_unit character varying(30) NOT NULL
);


ALTER TABLE public.units OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 93933)
-- Name: units_id_unit_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.units ALTER COLUMN id_unit ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.units_id_unit_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 216 (class 1259 OID 93920)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id_user bigint NOT NULL,
    full_name character varying(255) NOT NULL,
    login character varying(100) NOT NULL,
    password_hash text NOT NULL,
    role character varying(20) NOT NULL,
    is_blocked boolean DEFAULT false NOT NULL,
    failed_attempts smallint DEFAULT 0 NOT NULL,
    CONSTRAINT users_failed_attempts_check CHECK (((failed_attempts >= 0) AND (failed_attempts <= 3))),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY (ARRAY[('Администратор'::character varying)::text, ('Пользователь'::character varying)::text])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 93919)
-- Name: users_id_user_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.users ALTER COLUMN id_user ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.users_id_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 5022 (class 0 OID 93997)
-- Dependencies: 243
-- Data for Name: captcha_challenges; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.captcha_challenges (challenge_id, correct_answer, expires_at, is_used) FROM stdin;
QUMtiaYflphj6ZpJ1voJH6fW7lacNfdmg_WH2oBe1-E	8	2026-11-03 20:11:47.101537+03	f
KZO3VVMK8816oB-Xy3_YNVvymrDQQGeVnOVe-60CNSQ	9	2026-11-03 20:11:47.193407+03	t
cvU5P4dPFB_IjFCLFWqwiKE1QVm2Hu6146Nie-Lj8Qo	8	2026-11-03 20:11:47.215409+03	t
\.


--
-- TOC entry 5023 (class 0 OID 94001)
-- Dependencies: 244
-- Data for Name: captcha_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.captcha_tokens (token, expires_at, is_used) FROM stdin;
8sHbS67d56XMtM5At_c_qa-s86t3Run3AqSKyageGEs	2026-11-03 20:14:47.215409+03	f
bqztAzRHq-H412aUAMv1j0AvaTjf-ZIdJ3ffHfZrI7Q	2026-11-03 20:14:47.23248+03	t
3aEWA2Kn132xR8lvoYaYWXg9RQYFHw8kPllJQaTTU0c	2026-11-03 20:14:47.27782+03	t
wCLg91_tMgaMyH1ESHBW2T5kdUKurCskZRCjj00MWYQ	2026-11-03 20:14:47.346032+03	f
S1QEZ6x81W4zlVBZkCn8OhgW3Oss6D4-rtS-pc6DFUg	2026-11-03 20:14:47.346032+03	t
7pW5Oqcw16Gf9Q52tqD8LM7ZByk1UZqJAzEgSvBicOU	2026-11-03 20:14:47.459759+03	t
Q8QMkvbzdwQTbfWGT56IVv7ABn-MnbLnsz4dG5ClDwA	2026-11-03 20:14:47.575498+03	t
z-F-25SV9tzdg4hzabUcYMECZBFnLBMl-c7JRmWKeps	2026-11-03 20:14:47.796221+03	t
UQisQxYAD5jzgzBNfXPf3yXAJTngH0Iy6Spkvp5t-88	2026-11-03 20:14:47.908652+03	t
hNK_44ODBwZ3brqGrctxM4nvib8va7rbbduao7aaP2Q	2026-11-03 20:14:48.066645+03	t
Lt2j2zo_iIwmAtlccAiW8p-uXOpN2QdKTaMtouubtNo	2026-11-03 20:14:48.277386+03	t
WurtAM1_5ICOy5D-HbiTuWlXSwfap3YBwjMHX2Pnqgg	2026-11-03 20:14:48.438629+03	t
\.


--
-- TOC entry 4997 (class 0 OID 93930)
-- Dependencies: 218
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id_category, category_name) FROM stdin;
1	Мебель
\.


--
-- TOC entry 5003 (class 0 OID 93942)
-- Dependencies: 224
-- Data for Name: counterparties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.counterparties (id_counterparty, external_id, name, inn, address, phone, counterparty_type) FROM stdin;
1	\N	ИП Томилин Александр Сергеевич	\N	\N	\N	Покупатель
\.


--
-- TOC entry 5015 (class 0 OID 93974)
-- Dependencies: 236
-- Data for Name: customer_order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_order_items (id_order_item, id_order, id_product, quantity, unit_price, discount_percent) FROM stdin;
1	1	1	2.000	14120.00	5.00
\.


--
-- TOC entry 5013 (class 0 OID 93969)
-- Dependencies: 234
-- Data for Name: customer_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_orders (id_order, order_number, order_date, id_customer, status) FROM stdin;
1	ЗП-0001	2026-04-22	1	Принят
\.


--
-- TOC entry 5021 (class 0 OID 93991)
-- Dependencies: 242
-- Data for Name: notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notes (id, title, content, id_user, created_at) FROM stdin;
5	План производства	Подготовить материалы для кухонного стола.	1	2026-04-23 09:00:00
6	Заказ покупателя	Проверить количество изделий и размер скидки.	1	2026-04-23 12:00:00
7	Проверка спецификации	Сверить нормы расхода материалов и операций.	1	2026-04-23 10:30:00
\.


--
-- TOC entry 5001 (class 0 OID 93938)
-- Dependencies: 222
-- Data for Name: product_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_types (id_type, type_name) FROM stdin;
1	Готовая продукция
\.


--
-- TOC entry 5019 (class 0 OID 93986)
-- Dependencies: 240
-- Data for Name: production_order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.production_order_items (id_production_item, id_production_order, id_product, quantity) FROM stdin;
1	1	1	2.000
\.


--
-- TOC entry 5017 (class 0 OID 93982)
-- Dependencies: 238
-- Data for Name: production_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.production_orders (id_production_order, order_number, launch_date, department) FROM stdin;
1	ПЗ-0001	2026-04-23	Основное подразделение
\.


--
-- TOC entry 5005 (class 0 OID 93949)
-- Dependencies: 226
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (id_product, code, name, id_type, id_category) FROM stdin;
1	ФР-00000034	Стол кухонный "Самобранка"	1	1
\.


--
-- TOC entry 5007 (class 0 OID 93953)
-- Dependencies: 228
-- Data for Name: resources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resources (id_resource, code, name, resource_kind, id_unit, unit_price) FROM stdin;
1	ФР-00000026	Опора	Материал	1	245.00
2	ФР-00000016	Мебельная деталь 600х800	Материал	1	140.00
3	ФР-00000013	Мебельная деталь 500х800	Материал	1	95.00
4	ФР-00000009	Столешница круглая	Материал	1	3250.00
5	ФР-00000027	Евровинт 6,5х5	Материал	2	595.00
6	ФР-00000494	Упаковка	Операция	3	950.00
7	ФР-00000052	Распил ДСП, МДФ и листового материала	Операция	3	450.00
8	ФР-00000053	Сборка модулей	Операция	3	1400.00
\.


--
-- TOC entry 5011 (class 0 OID 93964)
-- Dependencies: 232
-- Data for Name: specification_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specification_items (id_specification_item, id_specification, id_resource, norm_quantity) FROM stdin;
1	1	1	4.0000
2	1	2	4.0000
3	1	3	2.0000
4	1	4	1.0000
5	1	5	0.0120
6	1	6	0.5000
7	1	7	1.5000
8	1	8	0.7500
\.


--
-- TOC entry 5009 (class 0 OID 93959)
-- Dependencies: 230
-- Data for Name: specifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specifications (id_specification, id_product, manufacturer, valid_from) FROM stdin;
1	1	ООО ТД "Вершина"	2026-04-23
\.


--
-- TOC entry 4999 (class 0 OID 93934)
-- Dependencies: 220
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.units (id_unit, metric_unit) FROM stdin;
1	шт
2	тыс. шт
3	ч
\.


--
-- TOC entry 4995 (class 0 OID 93920)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id_user, full_name, login, password_hash, role, is_blocked, failed_attempts) FROM stdin;
1	Тестовый пользователь	user25	REPLACE_WITH_ARGON2_HASH	Пользователь	f	0
2	string	string	$argon2id$v=19$m=65536,t=3,p=4$t8WkNG8QtrdjTTZs5d9ONQ$YBjMWhYlItndN1EXTmgBIHH8/EzmL/wq3R0mfXrInIM	Пользователь	t	3
3	Sokolovskii Alexey	Alexey	$argon2id$v=19$m=65536,t=3,p=4$SZ7qA426RZ+ko8wIpOuCng$7N6/s+YsyQUqe3DmDHtZa2Jme9tix/AyVpH9RmTORRg	Пользователь	f	0
\.


--
-- TOC entry 5029 (class 0 OID 0)
-- Dependencies: 217
-- Name: categories_id_category_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_category_seq', 1, true);


--
-- TOC entry 5030 (class 0 OID 0)
-- Dependencies: 223
-- Name: counterparties_id_counterparty_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.counterparties_id_counterparty_seq', 1, true);


--
-- TOC entry 5031 (class 0 OID 0)
-- Dependencies: 235
-- Name: customer_order_items_id_order_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_order_items_id_order_item_seq', 1, true);


--
-- TOC entry 5032 (class 0 OID 0)
-- Dependencies: 233
-- Name: customer_orders_id_order_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_orders_id_order_seq', 1, true);


--
-- TOC entry 5033 (class 0 OID 0)
-- Dependencies: 241
-- Name: notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notes_id_seq', 7, true);


--
-- TOC entry 5034 (class 0 OID 0)
-- Dependencies: 221
-- Name: product_types_id_type_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_types_id_type_seq', 1, true);


--
-- TOC entry 5035 (class 0 OID 0)
-- Dependencies: 239
-- Name: production_order_items_id_production_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.production_order_items_id_production_item_seq', 1, true);


--
-- TOC entry 5036 (class 0 OID 0)
-- Dependencies: 237
-- Name: production_orders_id_production_order_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.production_orders_id_production_order_seq', 1, true);


--
-- TOC entry 5037 (class 0 OID 0)
-- Dependencies: 225
-- Name: products_id_product_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_id_product_seq', 1, true);


--
-- TOC entry 5038 (class 0 OID 0)
-- Dependencies: 227
-- Name: resources_id_resource_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.resources_id_resource_seq', 8, true);


--
-- TOC entry 5039 (class 0 OID 0)
-- Dependencies: 231
-- Name: specification_items_id_specification_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.specification_items_id_specification_item_seq', 8, true);


--
-- TOC entry 5040 (class 0 OID 0)
-- Dependencies: 229
-- Name: specifications_id_specification_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.specifications_id_specification_seq', 1, true);


--
-- TOC entry 5041 (class 0 OID 0)
-- Dependencies: 219
-- Name: units_id_unit_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.units_id_unit_seq', 3, true);


--
-- TOC entry 5042 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_user_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_user_seq', 14, true);


--
-- TOC entry 4836 (class 2606 OID 94056)
-- Name: captcha_challenges captcha_challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.captcha_challenges
    ADD CONSTRAINT captcha_challenges_pkey PRIMARY KEY (challenge_id);


--
-- TOC entry 4838 (class 2606 OID 94058)
-- Name: captcha_tokens captcha_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.captcha_tokens
    ADD CONSTRAINT captcha_tokens_pkey PRIMARY KEY (token);


--
-- TOC entry 4784 (class 2606 OID 94012)
-- Name: categories categories_category_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_category_name_key UNIQUE (category_name);


--
-- TOC entry 4786 (class 2606 OID 94010)
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id_category);


--
-- TOC entry 4796 (class 2606 OID 94024)
-- Name: counterparties counterparties_external_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.counterparties
    ADD CONSTRAINT counterparties_external_id_key UNIQUE (external_id);


--
-- TOC entry 4798 (class 2606 OID 94022)
-- Name: counterparties counterparties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.counterparties
    ADD CONSTRAINT counterparties_pkey PRIMARY KEY (id_counterparty);


--
-- TOC entry 4823 (class 2606 OID 94046)
-- Name: customer_order_items customer_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order_items
    ADD CONSTRAINT customer_order_items_pkey PRIMARY KEY (id_order_item);


--
-- TOC entry 4819 (class 2606 OID 94044)
-- Name: customer_orders customer_orders_order_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_orders
    ADD CONSTRAINT customer_orders_order_number_key UNIQUE (order_number);


--
-- TOC entry 4821 (class 2606 OID 94042)
-- Name: customer_orders customer_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_orders
    ADD CONSTRAINT customer_orders_pkey PRIMARY KEY (id_order);


--
-- TOC entry 4834 (class 2606 OID 94054)
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- TOC entry 4792 (class 2606 OID 94018)
-- Name: product_types product_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_pkey PRIMARY KEY (id_type);


--
-- TOC entry 4794 (class 2606 OID 94020)
-- Name: product_types product_types_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_type_name_key UNIQUE (type_name);


--
-- TOC entry 4830 (class 2606 OID 94052)
-- Name: production_order_items production_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_order_items
    ADD CONSTRAINT production_order_items_pkey PRIMARY KEY (id_production_item);


--
-- TOC entry 4826 (class 2606 OID 94050)
-- Name: production_orders production_orders_order_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_order_number_key UNIQUE (order_number);


--
-- TOC entry 4828 (class 2606 OID 94048)
-- Name: production_orders production_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id_production_order);


--
-- TOC entry 4802 (class 2606 OID 94028)
-- Name: products products_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_code_key UNIQUE (code);


--
-- TOC entry 4804 (class 2606 OID 94026)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id_product);


--
-- TOC entry 4806 (class 2606 OID 94032)
-- Name: resources resources_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resources
    ADD CONSTRAINT resources_code_key UNIQUE (code);


--
-- TOC entry 4808 (class 2606 OID 94030)
-- Name: resources resources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resources
    ADD CONSTRAINT resources_pkey PRIMARY KEY (id_resource);


--
-- TOC entry 4815 (class 2606 OID 94040)
-- Name: specification_items specification_items_id_specification_id_resource_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specification_items
    ADD CONSTRAINT specification_items_id_specification_id_resource_key UNIQUE (id_specification, id_resource);


--
-- TOC entry 4817 (class 2606 OID 94038)
-- Name: specification_items specification_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specification_items
    ADD CONSTRAINT specification_items_pkey PRIMARY KEY (id_specification_item);


--
-- TOC entry 4810 (class 2606 OID 94036)
-- Name: specifications specifications_id_product_valid_from_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specifications
    ADD CONSTRAINT specifications_id_product_valid_from_key UNIQUE (id_product, valid_from);


--
-- TOC entry 4812 (class 2606 OID 94034)
-- Name: specifications specifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specifications
    ADD CONSTRAINT specifications_pkey PRIMARY KEY (id_specification);


--
-- TOC entry 4788 (class 2606 OID 94016)
-- Name: units units_metric_unit_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_metric_unit_key UNIQUE (metric_unit);


--
-- TOC entry 4790 (class 2606 OID 94014)
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (id_unit);


--
-- TOC entry 4780 (class 2606 OID 94008)
-- Name: users users_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_login_key UNIQUE (login);


--
-- TOC entry 4782 (class 2606 OID 94006)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id_user);


--
-- TOC entry 4831 (class 1259 OID 94119)
-- Name: ix_notes_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notes_created_at ON public.notes USING btree (created_at);


--
-- TOC entry 4832 (class 1259 OID 94120)
-- Name: ix_notes_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notes_user ON public.notes USING btree (id_user);


--
-- TOC entry 4824 (class 1259 OID 94121)
-- Name: ix_order_items_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_order_items_order ON public.customer_order_items USING btree (id_order);


--
-- TOC entry 4799 (class 1259 OID 94122)
-- Name: ix_products_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_products_category ON public.products USING btree (id_category);


--
-- TOC entry 4800 (class 1259 OID 94123)
-- Name: ix_products_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_products_type ON public.products USING btree (id_type);


--
-- TOC entry 4813 (class 1259 OID 94124)
-- Name: ix_spec_items_spec; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_spec_items_spec ON public.specification_items USING btree (id_specification);


--
-- TOC entry 4846 (class 2606 OID 94094)
-- Name: customer_order_items customer_order_items_id_order_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order_items
    ADD CONSTRAINT customer_order_items_id_order_fkey FOREIGN KEY (id_order) REFERENCES public.customer_orders(id_order) ON DELETE CASCADE;


--
-- TOC entry 4847 (class 2606 OID 94099)
-- Name: customer_order_items customer_order_items_id_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order_items
    ADD CONSTRAINT customer_order_items_id_product_fkey FOREIGN KEY (id_product) REFERENCES public.products(id_product);


--
-- TOC entry 4845 (class 2606 OID 94089)
-- Name: customer_orders customer_orders_id_customer_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_orders
    ADD CONSTRAINT customer_orders_id_customer_fkey FOREIGN KEY (id_customer) REFERENCES public.counterparties(id_counterparty);


--
-- TOC entry 4850 (class 2606 OID 94114)
-- Name: notes notes_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- TOC entry 4848 (class 2606 OID 94109)
-- Name: production_order_items production_order_items_id_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_order_items
    ADD CONSTRAINT production_order_items_id_product_fkey FOREIGN KEY (id_product) REFERENCES public.products(id_product);


--
-- TOC entry 4849 (class 2606 OID 94104)
-- Name: production_order_items production_order_items_id_production_order_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_order_items
    ADD CONSTRAINT production_order_items_id_production_order_fkey FOREIGN KEY (id_production_order) REFERENCES public.production_orders(id_production_order) ON DELETE CASCADE;


--
-- TOC entry 4839 (class 2606 OID 94064)
-- Name: products products_id_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_id_category_fkey FOREIGN KEY (id_category) REFERENCES public.categories(id_category);


--
-- TOC entry 4840 (class 2606 OID 94059)
-- Name: products products_id_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_id_type_fkey FOREIGN KEY (id_type) REFERENCES public.product_types(id_type);


--
-- TOC entry 4841 (class 2606 OID 94069)
-- Name: resources resources_id_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resources
    ADD CONSTRAINT resources_id_unit_fkey FOREIGN KEY (id_unit) REFERENCES public.units(id_unit);


--
-- TOC entry 4843 (class 2606 OID 94084)
-- Name: specification_items specification_items_id_resource_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specification_items
    ADD CONSTRAINT specification_items_id_resource_fkey FOREIGN KEY (id_resource) REFERENCES public.resources(id_resource);


--
-- TOC entry 4844 (class 2606 OID 94079)
-- Name: specification_items specification_items_id_specification_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specification_items
    ADD CONSTRAINT specification_items_id_specification_fkey FOREIGN KEY (id_specification) REFERENCES public.specifications(id_specification) ON DELETE CASCADE;


--
-- TOC entry 4842 (class 2606 OID 94074)
-- Name: specifications specifications_id_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specifications
    ADD CONSTRAINT specifications_id_product_fkey FOREIGN KEY (id_product) REFERENCES public.products(id_product);


-- Completed on 2026-11-04 22:18:36

--
-- PostgreSQL database dump complete
--

